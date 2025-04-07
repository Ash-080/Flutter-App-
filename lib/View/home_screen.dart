import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:translator/translator.dart';
import '../pages/recipe_search_page.dart';
import 'donation_page.dart';
import 'expiry_page_tracker.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GoogleTranslator translator = GoogleTranslator();
  String selectedLanguage = 'en';

  Future<String> translateText(String text) async {
    final translation = await translator.translate(text, to: selectedLanguage);
    return translation.text;
  }

  void updateLanguage(String languageCode) {
    setState(() {
      selectedLanguage = languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String userName = user?.displayName ?? 'User';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFAA87A9),
        elevation: 0,
        title: FutureBuilder(
          future: translateText('FreshByte'),
          builder: (context, snapshot) {
            return Text(
              snapshot.hasData ? snapshot.data! : 'FreshByte',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                color: Colors.white,
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: updateLanguage,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en', child: Text("English")),
              const PopupMenuItem(value: 'hi', child: Text("हिन्दी")),
              const PopupMenuItem(value: 'mr', child: Text("मराठी")),
            ],
            icon: const Icon(Icons.language, color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF6F1F1), Color(0xFFFAF7F7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  _buildCarouselSection(),
                  const SizedBox(height: 40),
                  _buildFeaturesSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildFooter(),
    );
  }

  Widget _buildCarouselSection() {
    List<String> carouselImages = [
      'assets/images/f1234.jpg',
      'assets/images/f123.gif',
      'assets/images/rec1.gif',
      'assets/images/foo1.gif',
      'assets/images/foo2.gif',

    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CarouselSlider.builder(
        itemCount: carouselImages.length,
        itemBuilder: (context, index, realIndex) {
          return Image.asset(
            carouselImages[index],
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
          );
        },
        options: CarouselOptions(
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 6),
          enlargeCenterPage: true,
          aspectRatio: 16 / 9,
          scrollPhysics: const BouncingScrollPhysics(),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FutureBuilder<String>(
          future: translateText("Features"),
          builder: (context, snapshot) {
            return Text(
              snapshot.hasData ? snapshot.data! : "Features",
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0C0C0C),
              ),
              textAlign: TextAlign.center,
            );
          },
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            _buildFeatureCard(
              context,
              title: "Donate Food",
              icon: Icons.favorite,
              color: const Color(0xFFF1C796),
              description: "Share excess food with NGOs.",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DonateFoodPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildFeatureCard(
              context,
              title: "Explore Recipes",
              icon: Icons.receipt_long,
              color: const Color(0xFFC59BC4),
              description: "Discover recipes for your leftovers.",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RecipeSearchPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildFeatureCard(
              context,
              title: "Track Expiry",
              icon: Icons.notifications,
              color: const Color(0xFFEC9A9A),
              description: "Get reminders for expiring food.",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExpiryPage()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required String description,
        required VoidCallback onPressed,
      }) {
    return FutureBuilder<String>(
      future: translateText(title),
      builder: (context, titleSnapshot) {
        return FutureBuilder<String>(
          future: translateText(description),
          builder: (context, descSnapshot) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 48, color: color),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleSnapshot.hasData ? titleSnapshot.data! : title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          descSnapshot.hasData ? descSnapshot.data! : description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Go"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      color: const Color(0xFF9C6A8E),
      padding: const EdgeInsets.all(20),
      child: FutureBuilder<String>(
        future: translateText("\u00A9 2024 FreshByte. All rights reserved."),
        builder: (context, snapshot) {
          return Text(
            snapshot.hasData ? snapshot.data! : "\u00A9 2024 FreshByte. All rights reserved.",
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          );
        },
      ),
    );
  }
}