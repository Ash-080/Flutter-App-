import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
//"9136b62d90mshb1362ab53443611p1f72e7jsn3fd03fd38895"; // Replace with your

class ApiService {
  static const String tastyApiUrl = "https://tasty.p.rapidapi.com/recipes/list";
  static const String tastyDetailApiUrl =
      "https://tasty.p.rapidapi.com/recipes/get-more-info";
  static const String tastyApiKey =
      "9136b62d90mshb1362ab53443611p1f72e7jsn3fd03fd38895";
  static const Map<String, String> tastyHeaders = {
    "X-RapidAPI-Key": tastyApiKey,
    "X-RapidAPI-Host": "tasty.p.rapidapi.com",
  };

  Future<List<Map<String, dynamic>>> fetchRecipes(String ingredient) async {
    final response = await http.get(
      Uri.parse(
          'https://www.themealdb.com/api/json/v1/1/filter.php?i=$ingredient'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> meals = data['meals'] ?? [];

      return meals.map((meal) {
        return {
          'title': meal['strMeal'],
          'image': meal['strMealThumb'],
          'id': meal['idMeal'],
          'source': 'TheMealDB',
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch recipes from TheMealDB API');
    }
  }

  Future<List<Map<String, dynamic>>> fetchTastyRecipes(
      String ingredient) async {
    final response = await http.get(
      Uri.parse("$tastyApiUrl?from=0&size=10&q=$ingredient"),
      headers: tastyHeaders,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> recipes = data['results'] ?? [];

      return recipes.map((recipe) {
        return {
          'title': recipe['name'],
          'image': recipe['thumbnail_url'],
          'id': recipe['id'].toString(),
          'source': 'Tasty',
        };
      }).toList();
    } else {
      throw Exception('Failed to fetch recipes from Tasty API');
    }
  }

  Future<Map<String, dynamic>> fetchRecipeDetails(String recipeId) async {
    final response = await http.get(
      Uri.parse(
          'https://www.themealdb.com/api/json/v1/1/lookup.php?i=$recipeId'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['meals'] != null ? data['meals'][0] : {};
    } else {
      throw Exception('Failed to fetch recipe details');
    }
  }

  Future<Map<String, dynamic>> fetchTastyRecipeDetails(String recipeId) async {
    final response = await http.get(
      Uri.parse("$tastyDetailApiUrl?id=$recipeId"),
      headers: tastyHeaders,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch Tasty recipe details');
    }
  }
}
