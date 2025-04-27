import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mealplanner/pages/recipes/widgets/popular_recipes.dart';
import 'package:mealplanner/pages/recipes/widgets/recipes_categories.dart';
import 'package:mealplanner/pages/recipes/widgets/recipes_search_bar.dart';
import 'package:mealplanner/pages/recipes/widgets/recommended_recipes.dart';
import 'package:mealplanner/pages/recipes/see_more_recipes_page.dart';
import 'package:mealplanner/providers/random_recipes_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:webfeed/webfeed.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:get_storage/get_storage.dart';

class RecipesPage extends ConsumerStatefulWidget {
  const RecipesPage({super.key});

  @override
  ConsumerState<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends ConsumerState<RecipesPage> {
  bool isLoggedIn = false;
  String userName = "";
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  Database? _database;

  final _storage = GetStorage();

  @override
  void initState() {
    super.initState();
    _initializeDB();
    _checkLoginStatus();
  }

  // Check if the user is already logged in
  void _checkLoginStatus() {
    final storedName = _storage.read('user_name');
    final storedEmail = _storage.read('user_email');

    if (storedName != null && storedEmail != null) {
      setState(() {
        userName = storedName;
        isLoggedIn = true;
      });
    }
  }

  // Initialize the local database
  Future<void> _initializeDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mealplanner.db');
    _database = await openDatabase(path, version: 1, onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE users(id INTEGER PRIMARY KEY, name TEXT, email TEXT, login_time TEXT)',
      );
    });
  }

  // Save user details in both the database and GetStorage
  Future<void> _saveUser(String name, String email) async {
    final timestamp = DateFormat.yMd().add_jm().format(DateTime.now());
    await _database?.insert('users', {
      'name': name,
      'email': email,
      'login_time': timestamp,
    });

    // Save to GetStorage for persistence
    await _storage.write('user_name', name);
    await _storage.write('user_email', email);
    await _storage.write('login_time', timestamp);

    // Send welcome email
    await _sendEmail(email, timestamp);
  }

  // Send a welcome email to the user
  Future<void> _sendEmail(String email, String timestamp) async {
    const username = 'sammie251981@gmail.com';
    const password = 'qmbz gida yjlt wflr';
    final smtpServer = gmail(username, password);

    final message = Message()
      ..from = const Address(username, 'Meal Planner')
      ..recipients.add(email)
      ..subject = 'Login Successful'
      ..text =
          'Hi $userName!\n\nYou logged in on $timestamp.\n\nBon appétit! 🍽️';

    try {
      await send(message, smtpServer);
    } catch (e) {
      debugPrint("Failed to send email: $e");
    }
  }

  // Fetch the current location of the user
  Future<Position> getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      throw Exception('Location permissions are denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition();
  }

  // Fetch RSS feed data
  Future<RssFeed?> fetchRssFeed() async {
    final response =
        await http.get(Uri.parse('https://www.bbcgoodfood.com/rss'));
    if (response.statusCode == 200) {
      return RssFeed.parse(response.body);
    }
    return null;
  }

  // UI to prompt user for login
  Widget _buildLoginUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("🍽️ Meal Planner",
                style: Theme.of(this.context).textTheme.displayMedium?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 40),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final email = _emailController.text.trim();
                if (name.isEmpty || email.isEmpty) return;
                setState(() => userName = name);
                await _saveUser(name, email);
                setState(() => isLoggedIn = true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
              child: const Text("Get Started",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!isLoggedIn) return Scaffold(body: _buildLoginUI());

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hi $userName", style: theme.textTheme.bodyLarge),
            FutureBuilder<Position>(
              future: getLocation(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text("Fetching location...",
                      style: TextStyle(fontSize: 12));
                } else if (snapshot.hasError) {
                  return const Text("📍Coimbatore, Tamil Nadu, India",
                      style: TextStyle(fontSize: 12));
                } else {
                  final position = snapshot.data!;
                  return Text(
                    "📍 Lat: ${position.latitude.toStringAsFixed(2)}, Long: ${position.longitude.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 12),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await _storage.erase(); // Clear all login data
                setState(() {
                  userName = "";
                  isLoggedIn = false;
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () async => ref.invalidate(randomRecipesProvider),
        child: SingleChildScrollView(
          // Wrapped the content inside SingleChildScrollView
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RecipesSearchBar(),
                Text("Categories", style: theme.textTheme.titleLarge),
                const RecipesCategories(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Recommended for you",
                        style: theme.textTheme.titleLarge),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SeeMoreRecipesPage()),
                      ),
                      child: const Text("See more"),
                    ),
                  ],
                ),
                const RecommendedRecipes(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Recipes of the week",
                        style: theme.textTheme.titleLarge),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SeeMoreRecipesPage()),
                      ),
                      child: const Text("See more"),
                    ),
                  ],
                ),
                const PopularRecipes(),
                const SizedBox(height: 24),
                Text("Latest in Cooking 📰", style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                FutureBuilder<RssFeed?>(
                  future: fetchRssFeed(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return const Text("Error loading feed.");
                    }
                    final feed = snapshot.data;
                    if (feed == null) {
                      return const Text("No feed data.");
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // Prevents extra scrolling
                      itemCount: feed.items?.length ?? 0,
                      itemBuilder: (context, index) {
                        final item = feed.items![index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(item.title ?? "No Title",
                                style: theme.textTheme.titleLarge),
                            subtitle:
                                Text(item.pubDate?.toString() ?? "No Date"),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(item.title ?? "No Title"),
                                  content: Text(item.description ??
                                      "No Description Available."),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text("Close"),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
