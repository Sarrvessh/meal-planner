import 'package:get_storage/get_storage.dart';
import 'package:mealplanner/entities/complete_recipe.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bookmarks_provider.g.dart';

@riverpod
class Bookmarks extends _$Bookmarks {
  final _storage = GetStorage();

  late final String _userKey;

  // Initialize the userKey based on the user's email stored in GetStorage.
  Bookmarks() {
    final email = _storage.read<String>('email');
    if (email != null) {
      _userKey = 'bookmarks_$email'; // Create a unique key per user
    } else {
      _userKey = 'bookmarks_anon'; // Default for anonymous users
    }
  }

  @override
  FutureOr<List<CompleteRecipe>> build() {
    final userBookmarks = _storage.read<List<dynamic>>(_userKey) ?? [];
    // Convert the stored dynamic data into a list of CompleteRecipe.
    return userBookmarks.map((e) => CompleteRecipe.fromBookmark(e)).toList();
  }

  void add(CompleteRecipe meal) {
    final userBookmarks = _storage.read<List<dynamic>>(_userKey) ?? [];
    // Avoid adding duplicate recipes
    if (!userBookmarks.any((meal) => meal['id'] == meal.id)) {
      userBookmarks.add(meal.toMap());
      _storage.write(_userKey, userBookmarks);
      ref.invalidateSelf();
    }
  }

  void remove(String id) {
    final userBookmarks = _storage.read<List<dynamic>>(_userKey) ?? [];
    userBookmarks.removeWhere((meal) => meal['id'] == id);
    _storage.write(_userKey, userBookmarks);
    ref.invalidateSelf();
  }

  bool isBookmarked(String id) {
    final userBookmarks = _storage.read<List<dynamic>>(_userKey) ?? [];
    return userBookmarks.any((meal) => meal['id'] == id);
  }
}
