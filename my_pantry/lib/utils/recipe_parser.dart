import '../Models/recipe_model.dart';
import 'package:logging/logging.dart';

class RecipeParser {
  static final _logger = Logger('RecipeParser');
  
  static List<Recipe> parseRecipesFromJson(Map<String, dynamic> jsonResponse) {
    final List<Recipe> recipes = [];
    
    try {
      // Extract the recipes array from the JSON response
      final recipesData = jsonResponse['recipes'] as List<dynamic>;
      
      for (var recipeData in recipesData) {
        final recipe = recipeData as Map<String, dynamic>;
        
        // Parse ingredients as List<String>
        List<String> ingredients = [];
        if (recipe['ingredients'] != null) {
          final ingredientsData = recipe['ingredients'] as List<dynamic>;
          ingredients = ingredientsData.map((ingredient) => ingredient.toString()).toList();
        }
        
        recipes.add(Recipe(
          day: recipe['day']?.toString() ?? '',
          name: recipe['name']?.toString() ?? '',
          prepTime: recipe['prepTime']?.toString() ?? 'N/A',
          cookTime: recipe['cookTime']?.toString() ?? 'N/A',
          ingredients: ingredients,
          instructions: recipe['instructions']?.toString() ?? 'N/A',
        ));
      }
    } catch (e) {
      _logger.warning('Error parsing recipes from JSON: $e');
      // Return empty list if parsing fails
    }
    
    return recipes;
  }

  // Keep the old method for backward compatibility if needed
  static List<Recipe> parseRecipes(String responseText) {
    // This method is kept for backward compatibility
    // You can remove it if you're sure you won't need text parsing anymore
    final List<Recipe> recipes = [];
    // Remove the introductory sentence if present
    final relevantText = responseText.substring(responseText.indexOf("**Monday"));

    // Split the text into blocks for each day.
    // Assuming each recipe block is separated by at least two newlines and starts with "**Day:"
    final dayBlocks = relevantText.split(RegExp(r'\n\s*\n\s*(?=\*\*)'));

    for (var block in dayBlocks) {
      if (block.trim().isEmpty) continue;

      String day = '';
      String name = '';
      String prepTime = 'N/A';
      String cookTime = 'N/A';
      List<String> ingredients = [];
      String instructions = 'N/A';

      final lines = block.split('\n').map((line) => line.trim()).toList();

      // Extract Day and Name (e.g., "**Monday: Quick Turkey Tacos**")
      final titleLine = lines.firstWhere((line) => line.startsWith('**') && line.endsWith('**'), orElse: () => '');
      if (titleLine.isNotEmpty) {
        final titleContent = titleLine.replaceAll('**', '');
        final parts = titleContent.split(':');
        if (parts.length > 1) {
          day = parts[0].trim();
          name = parts.sublist(1).join(':').trim();
        } else {
          name = titleContent.trim(); // Or handle as an error/unknown
        }
      }

      for (final line in lines) {
        if (line.startsWith('* Prep Time:')) {
          prepTime = line.replaceFirst('* Prep Time:', '').trim();
        } else if (line.startsWith('* Cook Time:')) {
          cookTime = line.replaceFirst('* Cook Time:', '').trim();
        } else if (line.startsWith('* Ingredients:')) {
          final ingredientsText = line.replaceFirst('* Ingredients:', '').trim();
          // Split ingredients by comma and clean them up
          ingredients = ingredientsText.split(',').map((ingredient) => ingredient.trim()).toList();
        } else if (line.startsWith('* Instructions:')) {
          instructions = line.replaceFirst('* Instructions:', '').trim();
        }
      }
      
      // If instructions are multi-line, we might need more sophisticated parsing
      final instructionsStartIndex = block.indexOf('* Instructions:');
      if (instructionsStartIndex != -1) {
          final restOfBlockAfterInstructions = block.substring(instructionsStartIndex + '* Instructions:'.length);
          // Find the start of the next potential metadata item (like a new day or a completely new section)
          final nextAttributeIndex = restOfBlockAfterInstructions.indexOf('\n* ');
          if (nextAttributeIndex != -1) {
              instructions = restOfBlockAfterInstructions.substring(0, nextAttributeIndex).trim();
          } else {
              instructions = restOfBlockAfterInstructions.trim();
          }
      }

      if (name.isNotEmpty) { // Only add if we could parse a name
        recipes.add(Recipe(
          day: day,
          name: name,
          prepTime: prepTime,
          cookTime: cookTime,
          ingredients: ingredients,
          instructions: instructions,
        ));
      }
    }
    return recipes;
  }
}