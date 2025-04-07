import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:translator/translator.dart';

class RecipeDetailsPage extends StatefulWidget {
  final Map<String, dynamic> details;

  const RecipeDetailsPage({super.key, required this.details});

  @override
  _RecipeDetailsPageState createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends State<RecipeDetailsPage> {
  final translator = GoogleTranslator();
  String selectedLanguage = 'en'; // Default language is English
  bool isTranslating = false;

  String translatedTitle = "";
  List<String> translatedIngredients = [];
  List<String> translatedInstructions = [];

  @override
  void initState() {
    super.initState();
    _translateContent();
  }

  void _translateContent() async {
    setState(() => isTranslating = true);

    translatedTitle = await _translateText(
      widget.details['title'] ?? widget.details['strMeal'] ?? 'Recipe Details',
    );

    translatedIngredients = await Future.wait(
      _getIngredients().map((text) => _translateText(text)),
    );

    translatedInstructions = await Future.wait(
      _getInstructions().map((text) => _translateText(text)),
    );

    setState(() => isTranslating = false);
  }

  Future<String> _translateText(String text) async {
    try {
      return (await translator.translate(text, to: selectedLanguage)).text;
    } catch (e) {
      return text;
    }
  }

  List<String> _getIngredients() {
    List<String> ingredients = [];

    // Spoonacular API
    if (widget.details.containsKey('extendedIngredients')) {
      ingredients = widget.details['extendedIngredients']
          .map<String>((ingredient) => cleanText(ingredient['original']))
          .toList();
    }

    // TheMealDB API
    if (widget.details.containsKey('strIngredient1')) {
      for (int i = 1; i <= 20; i++) {
        final ingredient = widget.details['strIngredient$i'];
        if (ingredient != null && ingredient.isNotEmpty) {
          ingredients.add(cleanText(ingredient));
        }
      }
    }

    // Tasty API
    if (widget.details.containsKey('sections')) {
      for (var section in widget.details['sections']) {
        for (var component in section['components']) {
          ingredients.add(cleanText(component['raw_text']));
        }
      }
    }

    return ingredients;
  }

  List<String> _getInstructions() {
    List<String> instructions = [];

    // Spoonacular API
    if (widget.details.containsKey('analyzedInstructions') &&
        widget.details['analyzedInstructions'].isNotEmpty) {
      instructions = widget.details['analyzedInstructions'][0]['steps']
          .map<String>((step) => cleanText("Step ${step['number']}: ${step['step']}"))
          .toList();
    }

    // TheMealDB API
    if (widget.details.containsKey('strInstructions')) {
      List<String> steps = widget.details['strInstructions'].split('. ');
      for (int i = 0; i < steps.length; i++) {
        if (steps[i].trim().isNotEmpty) {
          instructions.add(cleanText("Step ${i + 1}: ${steps[i]}"));
        }
      }
    }

    // Tasty API
    if (widget.details.containsKey('instructions')) {
      for (var step in widget.details['instructions']) {
        instructions.add(cleanText("Step ${step['position']}: ${step['display_text']}"));
      }
    }

    return instructions;
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = widget.details['image'] ??
        widget.details['strMealThumb'] ??
        widget.details['thumbnail_url'];

    String? videoUrl = widget.details['sourceUrl'] ??
        widget.details['strYoutube'] ??
        widget.details['original_video_url'];

    return Scaffold(
      appBar: AppBar(
        title: Text(translatedTitle),
        backgroundColor: const Color.fromARGB(255, 218, 211, 234),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String newLang) {
              setState(() {
                selectedLanguage = newLang;
                _translateContent();
              });
            },

            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem(value: 'en', child: Text('English')),
                const PopupMenuItem(value: 'es', child: Text('Spanish')),
                const PopupMenuItem(value: 'fr', child: Text('French')),
                const PopupMenuItem(value: 'de', child: Text('German')),
                const PopupMenuItem(value: 'hi', child: Text('Hindi')),
                const PopupMenuItem(value: 'mr', child: Text('Marathi')),
                const PopupMenuItem(value: 'zh-cn', child: Text('Chinese')),
              ];
            },
            icon: const Icon(Icons.language, color: Colors.white),
          ),
        ],
      ),
      body: isTranslating
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Fixed Image at the Top
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: imageUrl ?? 'https://via.placeholder.com/250',
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Ingredients Section
                  _buildCard("Ingredients", translatedIngredients),

                  const SizedBox(height: 16),

                  // Instructions Section
                  _buildCard("Step-by-Step Instructions", translatedInstructions),

                  const SizedBox(height: 16),

                  // Video Section
                  if (videoUrl != null && videoUrl.isNotEmpty)
                    _buildVideoCard(videoUrl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, List<String> content) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Increased rounding
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            content.isNotEmpty
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: content.map((e) => Text("• $e", style: const TextStyle(fontSize: 16))).toList(),
            )
                : const Text("No data available"),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(String videoUrl) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Increased rounding
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Watch Video:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final Uri url = Uri.parse(videoUrl);
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.play_circle_fill, color: Colors.white),
              label: const Text("Watch Recipe Video", style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 191, 168, 220),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Function to clean unwanted characters from text
String cleanText(String text) {
  return text.replaceAll(RegExp(r'[^\x00-\x7F]'), '').trim();
}