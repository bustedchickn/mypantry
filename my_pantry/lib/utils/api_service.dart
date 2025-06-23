import 'dart:convert';
import 'package:http/http.dart' as http; // Add http package to pubspec.yaml http: ^1.4.0

class ApiService {
  final String _baseUrl = "http://localhost:11434/api/generate"; // e.g., http://localhost:11434/api/generate

  Future<Map<String, dynamic>> fetchRecipesFromOllama(List<String> ingredients) async {
  // Future fetchRecipesFromOllama() async {
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