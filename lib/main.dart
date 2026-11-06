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
                    Text('Consumed: ${eatenCal.toStringAsFixed(0)} /${targetCal.toStringAsFixed(0)} kcal'),
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
                        subtitle: Text('${(item['calories'] as num).toStringAsFixed(0)} kcal \vert{} P:${item['protein']}g | C: ${item['carbs']}g \vert{} F:${item['fat']}g'),
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
                          subtitle: Text('${ing['calories']} kcal per${ing['servingSize']}'),
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
                          title