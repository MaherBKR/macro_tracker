import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MacroTrackerApp());
}

class MacroTrackerApp extends StatelessWidget {
  const MacroTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Macro Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
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

  // Global App Data
  double targetCalories = 2500;
  double targetProtein = 180;
  double targetCarbs = 250;
  double targetFats = 70;

  List> ingredients = [];
  List> recipes = [];
  List> dailyLogs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      targetCalories = prefs.getDouble('targetCalories') ?? 2500;
      targetProtein = prefs.getDouble('targetProtein') ?? 180;
      targetCarbs = prefs.getDouble('targetCarbs') ?? 250;
      targetFats = prefs.getDouble('targetFats') ?? 70;

      ingredients = List>.from(
          jsonDecode(prefs.getString('ingredients') ?? '[]'));
      recipes = List>.from(
          jsonDecode(prefs.getString('recipes') ?? '[]'));
      dailyLogs = List>.from(
          jsonDecode(prefs.getString('dailyLogs') ?? '[]'));
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('targetCalories', targetCalories);
    await prefs.setDouble('targetProtein', targetProtein);
    await prefs.setDouble('targetCarbs', targetCarbs);
    await prefs.setDouble('targetFats', targetFats);

    await prefs.setString('ingredients', jsonEncode(ingredients));
    await prefs.setString('recipes', jsonEncode(recipes));
    await prefs.setString('dailyLogs', jsonEncode(dailyLogs));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardTab(
        targetCal: targetCalories,
        targetPro: targetProtein,
        targetCarb: targetCarbs,
        targetFat: targetFats,
        dailyLogs: dailyLogs,
        onLogItem: (item) {
          setState(() {
            dailyLogs.add({
              'name': item['name'],
              'calories': (item['calories'] as num).toDouble(),
              'protein': (item['protein'] as num).toDouble(),
              'carbs': (item['carbs'] as num).toDouble(),
              'fat': (item['fat'] as num).toDouble(),
              'date': DateTime.now().toIso8601String().substring(0, 10),
            });
            _saveData();
          });
        },
        ingredients: ingredients,
        recipes: recipes,
      ),
      IngredientsTab(
        ingredients: ingredients,
        onAddIngredient: (ing) {
          setState(() {
            ingredients.add(ing);
            _saveData();
          });
        },
      ),
      RecipesTab(
        ingredients: ingredients,
        recipes: recipes,
        onAddRecipe: (rec) {
          setState(() {
            recipes.add(rec);
            _saveData();
          });
        },
      ),
      SettingsTab(
        targetCalories: targetCalories,
        targetProtein: targetProtein,
        targetCarbs: targetCarbs,
        targetFats: targetFats,
        onUpdateTargets: (c, p, carb, f) {
          setState(() {
            targetCalories = c;
            targetProtein = p;
            targetCarbs = carb;
            targetFats = f;
            _saveData();
          });
        },
      ),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Tracker'),
          NavigationDestination(icon: Icon(Icons.kitchen_outlined), selectedIcon: Icon(Icons.kitchen), label: 'Ingredients'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Recipes'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Goals'),
        ],
      ),
    );
  }
}

// --- TAB 1: DASHBOARD ---
class DashboardTab extends StatelessWidget {
  final double targetCal, targetPro, targetCarb, targetFat;
  final List> dailyLogs;
  final Function(Map<String, dynamic>) onLogItem;
  final List> ingredients;
  final List> recipes;

  const DashboardTab({
    super.key,
    required this.targetCal,
    required this.targetPro,
    required this.targetCarb,
    required this.targetFat,
    required this.dailyLogs,
    required this.onLogItem,
    required this.ingredients,
    required this.recipes,
  });

  @override
  Widget build(BuildContext context) {
    String today = DateTime.now().toIso8601String().substring(0, 10);
    var todaysLogs = dailyLogs.where((e) => e['date'] == today).toList();

    double eatenCal = todaysLogs.fold<double>(0.0, (sum, item) => sum + (item['calories'] as num).toDouble());
    double eatenPro = todaysLogs.fold<double>(0.0, (sum, item) => sum + (item['protein'] as num).toDouble());
    double eatenCarb = todaysLogs.fold<double>(0.0, (sum, item) => sum + (item['carbs'] as num).toDouble());
    double eatenFat = todaysLogs.fold<double>(0.0, (sum, item) => sum + (item['fat'] as num).toDouble());

    return Scaffold(
      appBar: AppBar(title: Text('Today\'s Macros ($today)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Calories Remaining', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    Text('${(targetCal - eatenCal).toStringAsFixed(0)} kcal',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    LinearProgressIndicator(value: (eatenCal / targetCal).clamp(0.0, 1.0)),
                    const SizedBox(height: 12),
                    Text('Consumed: ${eatenCal.toStringAsFixed(0)} / ${targetCal.toStringAsFixed(0)} kcal'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildMacroCard('Protein', eatenPro, targetPro, 'g', Colors.redAccent),
                _buildMacroCard('Carbs', eatenCarb, targetCarb, 'g', Colors.amber),
                _buildMacroCard('Fats', eatenFat, targetFat, 'g', Colors.lightBlue),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Logged Today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  onPressed: () => _showQuickLogDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Log Meal'),
                ),
              ],
            ),
            const Divider(),
            todaysLogs.isEmpty
                ? const Padding(padding: EdgeInsets.all(32), child: Text('No entries logged today.'))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: todaysLogs.length,
                    itemBuilder: (context, index) {
                      final item = todaysLogs[index];
                      return ListTile(
                        title: Text(item['name']),
                        subtitle: Text('${(item['calories'] as num).toStringAsFixed(0)} kcal | P: ${item['protein']}g | C: ${item['carbs']}g | F: ${item['fat']}g'),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroCard(String label, double current, double target, String unit, Color color) {
    double remaining = target - current;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 8),
              Text('${remaining.toStringAsFixed(0)}$unit', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('left', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: (current / target).clamp(0.0, 1.0), color: color),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickLogDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const TabBar(
              tabs: [
                Tab(text: 'Ingredients'),
                Tab(text: 'Recipes'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              ingredients.isEmpty
                  ? const Center(child: Text('No ingredients added yet.'))
                  : ListView.builder(
                      itemCount: ingredients.length,
                      itemBuilder: (c, i) {
                        final ing = ingredients[i];
                        return ListTile(
                          title: Text(ing['name']),
                          subtitle: Text('${ing['calories']} kcal per ${ing['servingSize']}'),
                          onTap: () {
                            onLogItem(ing);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
              recipes.isEmpty
                  ? const Center(child: Text('No recipes created yet.'))
                  : ListView.builder(
                      itemCount: recipes.length,
                      itemBuilder: (c, i) {
                        final rec = recipes[i];
                        return ListTile(
                          title: Text(rec['name']),
                          subtitle: Text('${(rec['calories'] as num).toStringAsFixed(0)} kcal total'),
                          onTap: () {
                            onLogItem(rec);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- TAB 2: INGREDIENTS INVENTORY ---
class IngredientsTab extends StatelessWidget {
  final List> ingredients;
  final Function(Map<String, dynamic>) onAddIngredient;

  const IngredientsTab({super.key, required this.ingredients, required this.onAddIngredient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ingredient Inventory')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
      body: ingredients.isEmpty
          ? const Center(child: Text('No ingredients added yet.'))
          : ListView.builder(
              itemCount: ingredients.length,
              itemBuilder: (context, index) {
                final ing = ingredients[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.fastfood)),
                  title: Text(ing['name']),
                  subtitle: Text('Per ${ing['servingSize']}: ${ing['calories']} kcal | P: ${ing['protein']}g | C: ${ing['carbs']}g | F: ${ing['fat']}g'),
                );
              },
            ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final servingCtrl = TextEditingController(text: '100g');
    final calCtrl = TextEditingController();
    final proCtrl = TextEditingController();
    final carbCtrl = TextEditingController();
    final fatCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Ingredient'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ingredient Name')),
              TextField(controller: servingCtrl, decoration: const InputDecoration(labelText: 'Serving Unit (e.g., 100g, 1 piece)')),
              TextField(controller: calCtrl, decoration: const InputDecoration(labelText: 'Calories (kcal)'), keyboardType: TextInputType.number),
              TextField(controller: proCtrl, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number),
              TextField(controller: carbCtrl, decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: TextInputType.number),
              TextField(controller: fatCtrl, decoration: const InputDecoration(labelText: 'Fat (g)'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty) {
                onAddIngredient({
                  'name': nameCtrl.text,
                  'servingSize': servingCtrl.text,
                  'calories': double.tryParse(calCtrl.text) ?? 0,
                  'protein': double.tryParse(proCtrl.text) ?? 0,
                  'carbs': double.tryParse(carbCtrl.text) ?? 0,
                  'fat': double.tryParse(fatCtrl.text) ?? 0,
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// --- TAB 3: RECIPES CREATOR ---
class RecipesTab extends StatefulWidget {
  final List> ingredients;
  final List> recipes;
  final Function(Map<String, dynamic>) onAddRecipe;

  const RecipesTab({super.key, required this.ingredients, required this.recipes, required this.onAddRecipe});

  @override
  State<RecipesTab> createState() => _RecipesTabState();
}

class _RecipesTabState extends State<RecipesTab> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Recipes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBuildRecipeModal(context),
        child: const Icon(Icons.add),
      ),
      body: widget.recipes.isEmpty
          ? const Center(child: Text('No recipes built yet.'))
          : ListView.builder(
              itemCount: widget.recipes.length,
              itemBuilder: (context, index) {
                final rec = widget.recipes[index];
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.restaurant_menu)),
                  title: Text(rec['name']),
                  subtitle: Text('${(rec['calories'] as num).toStringAsFixed(0)} kcal | P: ${rec['protein']}g | C: ${rec['carbs']}g | F: ${rec['fat']}g'),
                );
              },
            ),
    );
  }

  void _showBuildRecipeModal(BuildContext context) {
    final recipeNameCtrl = TextEditingController();
    List> selectedIngredients = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          double totalCal = selectedIngredients.fold<double>(0.0, (s, item) => s + (item['calories'] as num).toDouble());
          double totalPro = selectedIngredients.fold<double>(0.0, (s, item) => s + (item['protein'] as num).toDouble());
          double totalCarb = selectedIngredients.fold<double>(0.0, (s, item) => s + (item['carbs'] as num).toDouble());
          double totalFat = selectedIngredients.fold<double>(0.0, (s, item) => s + (item['fat'] as num).toDouble());

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 16, right: 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Create New Recipe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextField(controller: recipeNameCtrl, decoration: const InputDecoration(labelText: 'Recipe Title')),
                  const SizedBox(height: 10),
                  Text('Total: ${totalCal.toStringAsFixed(0)} kcal | P: ${totalPro}g | C: ${totalCarb}g | F: ${totalFat}g',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                  const Divider(),
                  const Text('Tap ingredients from inventory to include:'),
                  SizedBox(
                    height: 150,
                    child: widget.ingredients.isEmpty
                        ? const Center(child: Text('Add ingredients to inventory first!'))
                        : ListView.builder(
                            itemCount: widget.ingredients.length,
                            itemBuilder: (c, i) {
                              final ing = widget.ingredients[i];
                              return ListTile(
                                dense: true,
                                title: Text(ing['name']),
                                subtitle: Text('${ing['calories']} kcal'),
                                trailing: const Icon(Icons.add_circle_outline),
                                onTap: () {
                                  setModalState(() {
                                    selectedIngredients.add(ing);
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (recipeNameCtrl.text.isNotEmpty && selectedIngredients.isNotEmpty) {
                        widget.onAddRecipe({
                          'name': recipeNameCtrl.text,
                          'calories': totalCal,
                          'protein': totalPro,
                          'carbs': totalCarb,
                          'fat': totalFat,
                          'ingredients': selectedIngredients,
                        });
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Save Recipe'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- TAB 4: GOALS / SETTINGS ---
class SettingsTab extends StatelessWidget {
  final double targetCalories, targetProtein, targetCarbs, targetFats;
  final Function(double, double, double, double) onUpdateTargets;

  SettingsTab({
    super.key,
    required this.targetCalories,
    required this.targetProtein,
    required this.targetCarbs,
    required this.targetFats,
    required this.onUpdateTargets,
  });

  final calCtrl = TextEditingController();
  final proCtrl = TextEditingController();
  final carbCtrl = TextEditingController();
  final fatCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    calCtrl.text = targetCalories.toStringAsFixed(0);
    proCtrl.text = targetProtein.toStringAsFixed(0);
    carbCtrl.text = targetCarbs.toStringAsFixed(0);
    fatCtrl.text = targetFats.toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Macro Targets')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: calCtrl, decoration: const InputDecoration(labelText: 'Target Calories (kcal)'), keyboardType: TextInputType.number),
            TextField(controller: proCtrl, decoration: const InputDecoration(labelText: 'Target Protein (g)'), keyboardType: TextInputType.number),
            TextField(controller: carbCtrl, decoration: const InputDecoration(labelText: 'Target Carbs (g)'), keyboardType: TextInputType.number),
            TextField(controller: fatCtrl, decoration: const InputDecoration(labelText: 'Target Fats (g)'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                onUpdateTargets(
                  double.tryParse(calCtrl.text) ?? 2500,
                  double.tryParse(proCtrl.text) ?? 180,
                  double.tryParse(carbCtrl.text) ?? 250,
                  double.tryParse(fatCtrl.text) ?? 70,
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Targets updated!')));
              },
              child: const Text('Update Targets'),
            ),
          ],
        ),
      ),
    );
  }
}