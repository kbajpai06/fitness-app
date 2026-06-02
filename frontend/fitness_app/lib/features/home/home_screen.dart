import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/app_card.dart';
import '../workout/workout_screen.dart';
import '../diet/diet_screen.dart';
import '../coach/coach_screen.dart';
import '../profile/profile_screen.dart';
import '../recovery/recovery_screen.dart';
import '../progress/progress_screen.dart';
import '../../widgets/shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // ✅ _screens must be INSIDE the class
  final List<Widget> _screens = [
    const _HomeTab(),
    const WorkoutScreen(),
    const DietScreen(),
    const CoachScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: NavigationBar(
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.accentDim,
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.accent),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center, color: AppColors.accent),
            label: 'Workout',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant, color: AppColors.accent),
            label: 'Diet',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble, color: AppColors.accent),
            label: 'Coach',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.accent),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _todayDiet;
  Map<String, dynamic>? _workoutPlan;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiClient.get('/auth/me'),
        ApiClient.get('/diet/today').catchError((_) => null),
        ApiClient.get('/workout/plan').catchError((_) => null),
      ]);
      if (mounted) {
        setState(() {
          _profile = results[0];
          _todayDiet = results[1];
          _workoutPlan = results[2];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: HomeShimmer());
    }

    final name =
        (_profile?['full_name'] as String?)?.split(' ').first ?? 'Champ';
    final goal = _profile?['fitness_goal'] ?? 'general_fitness';

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Replace the first SliverToBoxAdapter (header) with this:
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accentDim.withOpacity(0.4),
                      AppColors.background,
                    ],
                    stops: const [0.0, 0.6],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.easeOut,
                              builder: (_, val, child) => Opacity(
                                opacity: val,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - val)),
                                  child: child,
                                ),
                              ),
                              child: Text(
                                name,
                                style: Theme.of(
                                  context,
                                ).textTheme.displayMedium,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accentDim,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accent.withOpacity(0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.accent,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (_, val, child) =>
                          Opacity(opacity: val, child: child),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentDim,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accent.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              goal
                                  .toString()
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S OVERVIEW",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            context,
                            label: 'Calories',
                            value: _todayDiet != null
                                ? '${_todayDiet!['daily_targets']?['calories'] ?? '--'}'
                                : '--',
                            unit: 'kcal',
                            icon: Icons.local_fire_department_outlined,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _statCard(
                            context,
                            label: 'Protein',
                            value: _todayDiet != null
                                ? '${_todayDiet!['daily_targets']?['protein_g'] ?? '--'}'
                                : '--',
                            unit: 'g',
                            icon: Icons.egg_outlined,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S WORKOUT",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _workoutPlan == null
                        ? _emptyCard(
                            context,
                            icon: Icons.fitness_center,
                            title: 'No workout plan',
                            subtitle: 'Generate your personalized plan',
                            buttonLabel: 'Generate Plan',
                            onTap: () {},
                          )
                        : _workoutPreviewCard(context),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TODAY'S MEALS",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _todayDiet == null
                        ? _emptyCard(
                            context,
                            icon: Icons.restaurant,
                            title: 'No diet plan',
                            subtitle: 'Generate your 7-day meal plan',
                            buttonLabel: 'Generate Plan',
                            onTap: () {},
                          )
                        : _mealPreviewCard(context),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "QUICK ACTIONS",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RecoveryScreen(),
                              ),
                            ),
                            child: _quickAction(
                              context,
                              icon: Icons.bedtime_outlined,
                              label: 'Log Recovery',
                              color: const Color(0xFF5A8CF5),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProgressScreen(),
                              ),
                            ),
                            child: _quickAction(
                              context,
                              icon: Icons.monitor_weight_outlined,
                              label: 'Log Weight',
                              color: AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _quickAction(
                            context,
                            icon: Icons.chat_bubble_outline,
                            label: 'Ask Coach',
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _workoutPreviewCard(BuildContext context) {
    final sessions = (_workoutPlan?['sessions'] as List?) ?? [];
    final today = DateTime.now().weekday - 1;
    final session = sessions.firstWhere(
      (s) => s['day_of_week'] == today,
      orElse: () => sessions.isNotEmpty ? sessions[0] : null,
    );

    if (session == null) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 24),
            const SizedBox(width: 12),
            Text(
              'Rest day. Recover well!',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final exercises = (session['exercises'] as List?) ?? [];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                session['focus'] ?? 'Workout',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentDim,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${session['duration_mins']} min',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...exercises
              .take(3)
              .map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.arrow_right,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${e['name']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${e['sets']}×${e['reps']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          if (exercises.length > 3) ...[
            const SizedBox(height: 4),
            Text(
              '+${exercises.length - 3} more exercises',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _mealPreviewCard(BuildContext context) {
    final meals = (_todayDiet?['meals'] as List?) ?? [];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day ${_todayDiet?['cycle_day'] ?? 1} of 7',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '₹${_todayDiet?['estimated_cost_today_inr'] ?? '--'}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.success),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...meals.map(
            (meal) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  _mealIcon(meal['meal_type']),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meal['dish_name'] ?? meal['meal_type'],
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${meal['total_calories']} kcal · ${meal['total_protein_g']}g protein',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mealIcon(String? type) {
    final icons = {
      'breakfast': ('☀️', AppColors.warning),
      'lunch': ('🍱', AppColors.success),
      'dinner': ('🌙', const Color(0xFF5A8CF5)),
      'snack': ('🥜', AppColors.accent),
    };
    final data = icons[type] ?? ('🍽️', AppColors.textMuted);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: (data.$2 as Color).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: Text(data.$1, style: const TextStyle(fontSize: 16))),
    );
  }

  Widget _emptyCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textMuted,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
