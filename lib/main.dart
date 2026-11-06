import 'package:flutter/material.dart';

void main() {
  runApp(const MacroTrackerApp());
}

class MacroTrackerApp extends StatelessWidget {
  const MacroTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Macro Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List> dailyLogs = [];
  final List> ingredients = [];
  final List> recipes = [];

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      DashboardTab(
        dailyLogs: dailyLogs,
        ingredients: ingredients,
        recipes: recipes,
      ),
      IngredientsTab(
        ingredients: ingredients,
      ),
      RecipesTab(
        ingredients: ingredients,
        recipes: recipes,
      ),
      const SettingsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Macro Tracker'),
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: 'Ingredients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Recipes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  final List> dailyLogs;
  final List> ingredients;
  final List> recipes;

  const DashboardTab({
    super.key,
    required this.dailyLogs,
    required this.ingredients,
    required this.recipes,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Dashboard Overview'),
    );
  }
}

class IngredientsTab extends StatelessWidget {
  final List> ingredients;

  const IngredientsTab({
    super.key,
    required this.ingredients,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: ingredients.length,
      itemBuilder: (context, index) {
        final item = ingredients[index];
        return ListTile(
          title: Text(item['name'] ?? ''),
          subtitle: Text('Protein: ${item['protein']}g'),
        );
      },
    );
  }
}

class RecipesTab extends StatefulWidget {
  final List> ingredients;
  final List> recipes;

  const RecipesTab({
    super.key,
    required this.ingredients,
    required this.recipes,
  });

  @override
  State<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<RecipesTab> {
  final List> selectedIngredients = [];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Recipes Manager',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        if (selectedIngredients.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Selected Ingredients: ${selectedIngredients.length}'),
          ),
      ],
    );
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings & Preferences'),
    );
  }
}