import 'package:flutter/material.dart';
import '../Models/recipe_model.dart';
import '../utils/recipe_parser.dart';
import '../widgets/recipe_card.dart';
import '../utils/api_service.dart';

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
  late List<String> _ingredients;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Extract ingredients from navigation arguments
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is List<String>) {
      _ingredients = args;
    } else {
      _ingredients = [];
    }

    _loadRecipes();
  }

  void _loadRecipes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final jsonResponse = await _apiService.fetchRecipesFromOllama(_ingredients);
      final parsedRecipes = RecipeParser.parseRecipesFromJson(jsonResponse);

      setState(() {
        _recipes = parsedRecipes;
        _isLoading = false;
      });

      if (parsedRecipes.isEmpty) {
        setState(() {
          _errorMessage = "No recipes found.";
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
      ),
      body: _buildBody(),
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
