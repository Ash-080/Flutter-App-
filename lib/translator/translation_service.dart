import 'package:translator/translator.dart';

class TranslationService {
  static final translator = GoogleTranslator();

  // Translate text to the given language
  static Future<String> translate(String text, String targetLang) async {
    if (targetLang == "en") return text; // No translation needed for English
    try {
      final translation = await translator.translate(text, to: targetLang);
      return translation.text;
    } catch (e) {
      return text; // Return original text if translation fails
    }
  }
}
