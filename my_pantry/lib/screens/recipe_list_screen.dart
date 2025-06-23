import 'package:flutter/material.dart';
import '../Models/recipe_model.dart';
import '../utils/recipe_parser.dart';
import '../widgets/recipe_card.dart';
import '../utils/api_service.dart'; // Import your API service if needed

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  List<Recipe> _recipes = [];
  bool _isLoading = true;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  void _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Define the ingredients list to test
      final List<String> ingredients = [
        '2 pounds ground turkey, chicken or beef',
        '1½ pounds boneless chicken',
        '1 dozen eggs',
        '1 pack shredded cheddar or Mexican blend cheese',
        '1 package mixed salad greens of your choice',
        '1 package fresh or frozen vegetables of your choice',
        '1 box whole grain pasta',
        '1 jar marinara/pasta sauce',
        '1 box instant brown rice',
        '2 cans beans of your choice',
        '1 pack chili seasoning',
        '1 15-ounce can diced tomatoes or tomato sauce',
        '1 bottle soy sauce or teriyaki sauce',
        '1 jar salsa spice/herb blend of your choice',
        'Salad dressing of your choice'
      ];
      
      // Use the ApiService to fetch recipes
      final jsonResponse = await _apiService.fetchRecipesFromOllama(ingredients);
      
      // Parse the JSON response using the new parser
      final parsedRecipes = RecipeParser.parseRecipesFromJson(jsonResponse);
      
      setState(() {
        _recipes = parsedRecipes;
        _isLoading = false;
      });

      if (parsedRecipes.isEmpty) {
        setState(() {
          _errorMessage = "No recipes found in the API response.";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading recipes: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Meal Plan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecipes,
          ),
        ],
      )
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRecipes,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_recipes.isEmpty) {
      return const Center(child: Text('No recipes found.'));
    }

    return ListView.builder(
      itemCount: _recipes.length,
      itemBuilder: (context, index) {
        return RecipeCard(recipe: _recipes[index]);
      },
    );
  }
}