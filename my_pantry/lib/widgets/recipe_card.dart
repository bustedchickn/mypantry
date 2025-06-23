import 'package:flutter/material.dart';
import '../Models/recipe_model.dart';

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${recipe.day}: ${recipe.name}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                if (recipe.prepTime.isNotEmpty && recipe.prepTime != 'N/A') ...[
                  const Icon(Icons.timer_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text('Prep: ${recipe.prepTime}'),
                  const SizedBox(width: 16),
                ],
                if (recipe.cookTime.isNotEmpty && recipe.cookTime != 'N/A') ...[
                  const Icon(Icons.whatshot_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text('Cook: ${recipe.cookTime}'),
                ],
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              'Ingredients:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4.0),
            Text(recipe.ingredients.join(', ')),
            const SizedBox(height: 12.0),
            Text(
              'Instructions:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4.0),
            Text(recipe.instructions),
          ],
        ),
      ),
    );
  }
}