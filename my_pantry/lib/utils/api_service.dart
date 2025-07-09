import 'dart:convert';
import 'package:http/http.dart' as http; // Add http package to pubspec.yaml http: ^1.4.0
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String _baseUrl = "http://localhost:11434/api/generate"; // e.g., http://localhost:11434/api/generate

  String _ingredientsCacheKey(List<String> ingredients) {
    // Sort and join to ensure order doesn't matter
    final sorted = List<String>.from(ingredients)..sort();
    return 'recipes_cache_${sorted.join(',')}';
  }

  String _ingredientsTimeKey(List<String> ingredients) {
    final sorted = List<String>.from(ingredients)..sort();
    return 'recipes_cache_time_${sorted.join(',')}';
  }

  Future<Map<String, dynamic>> fetchRecipesFromOllamaPersistent(List<String> ingredients) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = _ingredientsCacheKey(ingredients);
    final timeKey = _ingredientsTimeKey(ingredients);

    final cachedData = prefs.getString(cacheKey);
    final cacheTime = prefs.getInt(timeKey);

    final now = DateTime.now().millisecondsSinceEpoch;
    final oneWeek = 7 * 24 * 60 * 60 * 1000;

    if (cachedData != null && cacheTime != null && (now - cacheTime) < oneWeek) {
      return json.decode(cachedData) as Map<String, dynamic>;
    }

    // Prepare the request body based on Ollama's API requirements
    final requestBody = {
      "model": "llama3.2",
      "prompt": "Suppose that you are a terrific chef. Create a menu for one week and be cooked or preprared bellow 30 min with the following ingridients please specified the prep time in minutes like 15 min, 20 min, etc, the cooking time will be also in minutes like 5min, 15min, etc, and the ingredient amount for every recipe:\n ${ingredients.join(', ')}. Do not include in the response special characters like <, >, {, }, etc. The response should be in JSON format with the following structure: {\"recipes\": [{\"day\": \"Monday\", \"name\": \"Recipe Name\", \"prepTime\": \"15 min\", \"cookTime\": \"20 min\", \"ingredients\": [\"ingredient1\", \"ingredient2\"], \"instructions\": \"Cooking instructions here.\"}]}""",
      "stream": false,
      "format": {
        "type": "object",
        "properties": {
          "recipes": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "day": { "type": "string" },
                "name": { "type": "string" },
                "prepTime": { "type": "string" },
                "cookTime": { "type": "string" },
                "ingredients": {
                  "type": "array",
                  "items": { "type": "string" }
                },
                "instructions": { "type": "string" }
              },
              "required": ["day", "name", "prepTime", "cookTime", "ingredients", "instructions"]
            }
          }
        },
        "required": ["recipes"]
      }
    };

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        var responseString = jsonResponse['response'];
        
        // Cache the response and timestamp
        prefs.setString(cacheKey, responseString);
        prefs.setInt(timeKey, now);
        
        // Parse the response string into a Map
        return json.decode(responseString) as Map<String, dynamic>;
      } else {
        // Handle server errors (e.g., 4xx, 5xx)
        throw Exception('Failed to load recipes from API: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // Handle network errors or other exceptions
      throw Exception('Error connecting to API: $e');
    }
  }

  Future<Map<String, dynamic>> fetchRecipesFromOllama(List<String> ingredients) async {
  // Future fetchRecipesFromOllama() async {
    // Prepare the request body based on Ollama's API requirements
    final requestBody = {
      "model": "llama3.2",
      "prompt": "Suppose that you are a terrific chef. Create a menu for one week and be cooked or preprared below 30 min with the following ingridients please specified the prep time in minutes like 15 min, 20 min, etc, the cooking time will be also in minutes like 5min, 15min, etc, and the ingredient amount for every recipe:\n ${ingredients.join(', ')}. Do not include in the response special characters like <, >, {, }, etc. The response should be in JSON format with the following structure: {\"recipes\": [{\"day\": \"Monday\", \"name\": \"Recipe Name\", \"prepTime\": \"15 min\", \"cookTime\": \"20 min\", \"ingredients\": [\"ingredient1\", \"ingredient2\"], \"instructions\": \"Cooking instructions here.\"}]}""",
      "stream": false,
      "format": {
        "type": "object",
        "properties": {
          "recipes": {
            "type": "array",
            "items": {
              "type": "object",
              "properties": {
                "day": { "type": "string" },
                "name": { "type": "string" },
                "prepTime": { "type": "string" },
                "cookTime": { "type": "string" },
                "ingredients": {
                  "type": "array",
                  "items": { "type": "string" }
                },
                "instructions": { "type": "string" }
              },
              "required": ["day", "name", "prepTime", "cookTime", "ingredients", "instructions"]
            }
          }
        },
        "required": ["recipes"]
      }
    };

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        var responseString = jsonResponse['response'];
        // Parse the response string into a Map
        return json.decode(responseString) as Map<String, dynamic>;
      } else {
        // Handle server errors (e.g., 4xx, 5xx)
        throw Exception('Failed to load recipes from API: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // Handle network errors or other exceptions
      throw Exception('Error connecting to API: $e');
    }
  }
}