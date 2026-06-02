import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  Map<String, dynamic>? _today;
  bool _loading = true;
  bool _generating = false;
  int _selectedDay = 1;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    try {
      final data = await ApiClient.get('/diet/today');
      if (mounted) {
        setState(() {
          _today = data;
          _selectedDay = data['cycle_day'] ?? 1;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDay(int day) async {
    setState(() => _loading = true);
    try {
      final data = await ApiClient.get('/diet/day/$day');
      if (mounted) setState(() { _today = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generatePlan() async {
    setState(() => _generating = true);
    try {
      await ApiClient.post('/diet/generate', {});
      await _loadToday();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()),
          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Color _mealColor(String? type) {
    switch (type) {
      case 'breakfast': return AppColors.warning;
      case 'lunch':     return AppColors.success;
      case 'dinner':    return const Color(0xFF5A8CF5);
      default:          return AppColors.accent;
    }
  }

  String _mealEmoji(String? type) {
    switch (type) {
      case 'breakfast': return '☀️';
      case 'lunch':     return '🍱';
      case 'dinner':    return '🌙';
      default:          return '🥜';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Nutrition',
                          style: Theme.of(context).textTheme.displayMedium),
                        if (_today != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '₹${_today!['estimated_cost_inr'] ?? _today!['estimated_cost_today_inr'] ?? '--'}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                          ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                if (_today == null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          const Icon(Icons.restaurant,
                            color: AppColors.textMuted, size: 64),
                          const SizedBox(height: 24),
                          Text('No diet plan yet',
                            style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          Text('Generate your 7-day Indian meal plan.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center),
                          const SizedBox(height: 32),
                          AppButton(
                            label: 'Generate Meal Plan',
                            onPressed: _generatePlan,
                            isLoading: _generating,
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[

                  // Macro targets
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("DAILY TARGETS",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _macroItem(context, 'Calories',
                                  '${_today!['daily_targets']?['calories'] ?? '--'}',
                                  'kcal', AppColors.warning),
                                _macroItem(context, 'Protein',
                                  '${_today!['daily_targets']?['protein_g'] ?? '--'}',
                                  'g', AppColors.accent),
                                _macroItem(context, 'Carbs',
                                  '${_today!['daily_targets']?['carbs_g'] ?? '--'}',
                                  'g', const Color(0xFF5A8CF5)),
                                _macroItem(context, 'Fats',
                                  '${_today!['daily_targets']?['fats_g'] ?? '--'}',
                                  'g', AppColors.success),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Day selector
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: 7,
                        itemBuilder: (context, i) {
                          final day = i + 1;
                          final isSelected = day == _selectedDay;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedDay = day);
                              _loadDay(day);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                  ? AppColors.accent
                                  : AppColors.surface,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: isSelected
                                    ? AppColors.accent
                                    : AppColors.border),
                              ),
                              child: Text('Day $day',
                                style: TextStyle(
                                  color: isSelected
                                    ? AppColors.background
                                    : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                )),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // Meals
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final meals = (_today!['meals'] as List?) ?? [];
                        if (i >= meals.length) return null;
                        final meal = meals[i];
                        final items = (meal['items'] as List?) ?? [];
                        final color = _mealColor(meal['meal_type']);

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Meal header
                                Row(children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(child: Text(
                                      _mealEmoji(meal['meal_type']),
                                      style: const TextStyle(fontSize: 18))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (meal['meal_type'] as String)
                                            .toUpperCase(),
                                          style: Theme.of(context)
                                            .textTheme.bodySmall?.copyWith(
                                            letterSpacing: 1.2,
                                            fontWeight: FontWeight.w700,
                                            color: color,
                                          )),
                                        Text(meal['dish_name'] ?? '',
                                          style: Theme.of(context)
                                            .textTheme.titleMedium),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('${meal['total_calories']} kcal',
                                        style: Theme.of(context)
                                          .textTheme.titleMedium),
                                      Text('${meal['total_protein_g']}g protein',
                                        style: Theme.of(context)
                                          .textTheme.bodySmall),
                                    ],
                                  ),
                                ]),

                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 12),

                                // Food items
                                ...items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                        children: [
                                          Text(item['food_name'],
                                            style: Theme.of(context)
                                              .textTheme.bodyMedium?.copyWith(
                                              color: AppColors.textPrimary)),
                                          if (item['food_name_hindi'] != null)
                                            Text(item['food_name_hindi'],
                                              style: Theme.of(context)
                                                .textTheme.bodySmall),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                      children: [
                                        Text('${item['quantity_g']}g',
                                          style: Theme.of(context)
                                            .textTheme.bodyMedium),
                                        Text('₹${item['cost_inr']}',
                                          style: Theme.of(context)
                                            .textTheme.bodySmall?.copyWith(
                                            color: AppColors.success)),
                                      ],
                                    ),
                                  ]),
                                )),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: (_today!['meals'] as List?)?.length ?? 0,
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                      child: AppButton(
                        label: 'Regenerate Plan',
                        onPressed: _generatePlan,
                        isLoading: _generating,
                        outlined: true,
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _macroItem(BuildContext context, String label,
      String value, String unit, Color color) {
    return Column(
      children: [
        Text(value,
          style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        Text(unit,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color.withOpacity(0.7))),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}