import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mealplanner/pages/favorites/see_more_favorite_recipes.dart';
import 'package:mealplanner/providers/bookmarks_provider.dart';
import 'package:mealplanner/utils/extensions.dart';
import '../../widgets/spinner.dart';
import '../recipes/recipe_details_page.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final box = GetStorage();
    final userEmail = box.read<String>('user_email');

    // If the user is not logged in, show a message
    if (userEmail == null) {
      return const Center(
        child: Text("Please login to view your favorite recipes."),
      );
    }

    // Fetch the user's bookmarks using the userEmail
    final bookmarks = ref.watch(bookmarksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Favourite Recipes"),
      ),
      body: bookmarks.when(
        data: (data) {
          // If no favorites are found
          if (data.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Image.asset('assets/recipe-book.png'),
                  ),
                  const SizedBox(height: 10),
                  Text("No favourites yet", style: theme.textTheme.titleLarge),
                ],
              ),
            );
          }

          // Group recipes by category
          final groupedBookmarks = data.groupBy((e) => e.category);

          // Display grouped recipes
          return ListView(
            padding: const EdgeInsets.all(16),
            children: groupedBookmarks.entries.map((e) {
              final category = e.key;
              final recipes = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      return SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemCount: recipes.length,
                          itemBuilder: (context, index) {
                            final recipe = recipes[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RecipeDetailsPage(recipe: recipe),
                                  ),
                                );
                              },
                              child: SizedBox(
                                height: 200,
                                width: 200,
                                child: Card(
                                  child: CachedNetworkImage(
                                    imageUrl: recipe.imageUrl,
                                    placeholder: (_, __) =>
                                        const Center(child: Spinner()),
                                    errorWidget: (_, __, ___) =>
                                        const Icon(Icons.error),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 14),
                        ),
                      );
                    }

                    // If screen width is less than 600px, display a vertical layout
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(category, style: theme.textTheme.titleLarge),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => SeeMoreFavoriteRecipesPage(
                                      category: category,
                                      recipes: recipes,
                                    ),
                                  ),
                                );
                              },
                              child: const Text("See more"),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 200,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RecipeDetailsPage(
                                          recipe: recipes.first),
                                    ),
                                  );
                                },
                                child: Card(
                                  child: CachedNetworkImage(
                                    imageUrl: recipes.first.imageUrl,
                                    placeholder: (_, __) =>
                                        const Center(child: Spinner()),
                                    errorWidget: (_, __, ___) =>
                                        const Icon(Icons.error),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Flexible(
                                      child: GestureDetector(
                                        onTap: () {
                                          final recipe = recipes.length > 1
                                              ? recipes[1]
                                              : recipes[0];
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => RecipeDetailsPage(
                                                  recipe: recipe),
                                            ),
                                          );
                                        },
                                        child: Card(
                                          child: CachedNetworkImage(
                                            imageUrl: recipes.length > 1
                                                ? recipes[1].imageUrl
                                                : recipes[0].imageUrl,
                                            width: double.infinity,
                                            placeholder: (_, __) =>
                                                const Center(child: Spinner()),
                                            errorWidget: (_, __, ___) =>
                                                const Icon(Icons.error),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Flexible(
                                      child: Stack(
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              final recipe = recipes.length > 2
                                                  ? recipes[2]
                                                  : recipes[0];
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      RecipeDetailsPage(
                                                          recipe: recipe),
                                                ),
                                              );
                                            },
                                            child: Card(
                                              child: CachedNetworkImage(
                                                imageUrl: recipes.length > 2
                                                    ? recipes[2].imageUrl
                                                    : recipes[0].imageUrl,
                                                width: double.infinity,
                                                placeholder: (_, __) =>
                                                    const Center(
                                                        child: Spinner()),
                                                errorWidget: (_, __, ___) =>
                                                    const Icon(Icons.error),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          if (recipes.length > 3)
                                            Positioned.fill(
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          SeeMoreFavoriteRecipesPage(
                                                        category: category,
                                                        recipes: recipes,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: ShapeDecoration(
                                                    shape:
                                                        ContinuousRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    color: Colors.black45,
                                                  ),
                                                  child: Text(
                                                    "+${recipes.length - 3}\nRecipes",
                                                    textAlign: TextAlign.center,
                                                    style: theme
                                                        .textTheme.titleLarge!
                                                        .copyWith(
                                                            color:
                                                                Colors.white),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
        error: (error, _) => Center(child: Text(error.toString())),
        loading: () => const Center(child: Spinner()),
      ),
    );
  }
}
