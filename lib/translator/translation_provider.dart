import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'translation_service.dart' show TranslationService;

class TranslationProvider with ChangeNotifier {
  String _currentLanguage = "en"; // Default language: English

  String get currentLanguage => _currentLanguage;

  // Set language and save it
  Future<void> setLanguage(String langCode) async {
    _currentLanguage = langCode;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', langCode);
    notifyListeners(); // Notify UI to update
  }

  // Load saved language at app startup
  Future<void> loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('selected_language') ?? "en";
    notifyListeners();
  }

  // Translate text dynamically
  Future<String> translate(String text) async {
    return await TranslationService.translate(text, _currentLanguage);
  }
}
