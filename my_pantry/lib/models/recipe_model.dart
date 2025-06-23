class Recipe {
  final String day;
  final String name;
  final String prepTime;
  final String cookTime;
  final List<String> ingredients;
  final String instructions;

  Recipe({
    required this.day,
    required this.name,
    required this.prepTime,
    required this.cookTime,
    required this.ingredients,
    required this.instructions,
  });

  @override
  String toString() {
    return 'Recipe(day: $day, name: $name, prepTime: $prepTime, cookTime: $cookTime, ingredients: $ingredients, instructions: $instructions)';
  }
}