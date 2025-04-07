import 'dart:async';
import 'package:FreshByte/Service/api_service.dart';
import 'package:FreshByte/pages/recipe_details_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class RecipeSearchPage extends StatefulWidget {
  const RecipeSearchPage({super.key});

  @override
  _RecipeSearchPageState createState() => _RecipeSearchPageState();
}

class _RecipeSearchPageState extends State<RecipeSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> _recipes = [];
  Set<String> favoriteRecipeIds = {}; // Stores user's favorite recipes
  bool _isLoading = false;
  Timer? _debounce;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    loadFavorites();
    _controller.addListener(_onSearchChanged);
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> loadFavorites() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteList = prefs.getStringList('favoriteRecipes') ?? [];
    setState(() {
      favoriteRecipeIds = favoriteList
          .map<String>((item) => json.decode(item)['title'].toString())
          .toSet();
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchRecipes();
    });
  }

  Future<void> searchRecipes() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _recipes = [];
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final mealDBRecipes = await apiService.fetchRecipes(query);
      final tastyRecipes = await apiService.fetchTastyRecipes(query);
      setState(() {
        _recipes = [...mealDBRecipes, ...tastyRecipes];
      });
    } catch (e) {
      debugPrint('Error fetching recipes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void toggleFavorite(Map<String, dynamic> recipe) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> favoriteList = prefs.getStringList('favoriteRecipes') ?? [];
    String recipeId = recipe['title'] ?? recipe['strMeal'] ?? 'Unknown Recipe';

    setState(() {
      if (favoriteRecipeIds.contains(recipeId)) {
        favoriteRecipeIds.remove(recipeId);
        favoriteList.removeWhere((item) => json.decode(item)['title'] == recipeId);
      } else {
        favoriteRecipeIds.add(recipeId);
        favoriteList.add(json.encode(recipe));
      }
    });

    await prefs.setStringList('favoriteRecipes', favoriteList);
  }

  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
          });
          searchRecipes();
        },
      );
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Finder'),
        backgroundColor: const Color(0xFFAA87A9),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Bar with Voice Search
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Enter an ingredient (e.g., chicken)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _isListening ? _stopListening : _startListening,
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : const Color(0xFFAA87A9),
                      ),
                    ),
                    //const SizedBox(width: 8),
                    // const Icon(Icons.search, color: Color(0xFFAA87A9)), // Search icon
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoading) const LinearProgressIndicator(),
            Expanded(
              child: _recipes.isEmpty && !_isLoading
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/giphy.gif', height: 150),
                    const SizedBox(height: 10),
                    Text(
                      'Start typing or use voice search',
                      style: TextStyle(color: Colors.purple.shade300),
                    ),
                  ],
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _recipes.length,
                itemBuilder: (context, index) {
                  final recipe = _recipes[index];
                  String recipeTitle = recipe['title'] ?? recipe['strMeal'] ?? 'Unknown Recipe';
                  String? imageUrl =
                      recipe['image'] ?? recipe['strMealThumb'] ?? recipe['thumbnail_url'];

                  return GestureDetector(
                    onTap: () async {
                      Map<String, dynamic> details;
                      if (recipe['source'] == 'TheMealDB') {
                        details = await apiService.fetchRecipeDetails(recipe['id']);
                      } else {
                        details = await apiService.fetchTastyRecipeDetails(recipe['id']);
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecipeDetailsPage(details: details),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl ?? 'https://via.placeholder.com/250',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const CircularProgressIndicator(),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(recipeTitle, overflow: TextOverflow.ellipsis),
                                ),
                                IconButton(
                                  icon: Icon(
                                    favoriteRecipeIds.contains(recipeTitle)
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: favoriteRecipeIds.contains(recipeTitle)
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  onPressed: () => toggleFavorite(recipe),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}