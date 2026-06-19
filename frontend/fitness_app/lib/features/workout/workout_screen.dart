import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'exercise_detail_screen.dart';
import 'package:lottie/lottie.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  Map<String, dynamic>? _plan;
  bool _loading = true;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    try {
      final data = await ApiClient.get('/workout/plan');
      if (mounted) setState(() { _plan = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generatePlan() async {
    setState(() => _generating = true);
    try {
      await ApiClient.post('/workout/generate', {});
      await _loadPlan();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Muscle group colors
  static const Map<String, Color> _muscleColors = {
    'chest':     Color(0xFFE85538),
    'back':      Color(0xFF5A8CF5),
    'shoulders': Color(0xFFF5A623),
    'biceps':    Color(0xFF4CAF82),
    'triceps':   Color(0xFFC8F55A),
    'legs':      Color(0xFF9B59B6),
    'glutes':    Color(0xFFE91E8C),
    'core':      Color(0xFF00BCD4),
    'full_body': Color(0xFFC8F55A),
  };

  Color _getMuscleColor(String? muscle) {
    return _muscleColors[muscle?.toLowerCase()] ?? AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : CustomScrollView(
              slivers: [

                // ── Header ──────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Workout',
                          style: Theme.of(context).textTheme.displayMedium),
                        const SizedBox(height: 4),
                        Text(
                          _plan != null
                            ? _plan!['name'] ?? ''
                            : 'No plan yet',
                          style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // ── Empty State ──────────────────────────────
                if (_plan == null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 40),
                          Lottie.asset(
                            'assets/animations/empty_workout.json',
                            width: 200, height: 200,
                            repeat: true,
                          ),
                          const SizedBox(height: 16),
                          Text('No workout plan yet',
                            style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          Text(
                            'Generate a personalized plan based on your goals.',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center),
                          const SizedBox(height: 32),
                          AppButton(
                            label: 'Generate My Plan',
                            onPressed: _generatePlan,
                            isLoading: _generating,
                            icon: Icons.auto_awesome,
                          ),
                        ],
                      ),
                    ),
                  )

                else ...[

                  // ── Sessions ─────────────────────────────
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final sessions =
                          (_plan!['sessions'] as List?) ?? [];
                        if (i >= sessions.length) return null;

                        final session  = sessions[i];
                        final dayName  =
                          _days[session['day_of_week'] as int];
                        final exercises =
                          (session['exercises'] as List?) ?? [];
                        final isToday  =
                          session['day_of_week'] ==
                          DateTime.now().weekday - 1;

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: AppCard(
                            color: isToday ? AppColors.accentDim : null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // Session header
                                Row(
                                  mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isToday
                                            ? AppColors.accent
                                            : AppColors.surfaceHigh,
                                          borderRadius:
                                            BorderRadius.circular(8),
                                        ),
                                        child: Text(dayName,
                                          style: TextStyle(
                                            color: isToday
                                              ? AppColors.background
                                              : AppColors.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          )),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(session['focus'] ?? '',
                                        style: Theme.of(context)
                                          .textTheme.titleLarge),
                                    ]),
                                    Row(children: [
                                      Text(
                                        '${session['duration_mins']} min',
                                        style: Theme.of(context)
                                          .textTheme.bodySmall),
                                      if (isToday) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppColors.accent,
                                            borderRadius:
                                              BorderRadius.circular(6),
                                          ),
                                          child: const Text('TODAY',
                                            style: TextStyle(
                                              color: AppColors.background,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.5,
                                            )),
                                        ),
                                      ],
                                    ]),
                                  ],
                                ),

                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 8),

                                // Hint text
                                Row(children: [
                                  const Icon(Icons.touch_app_outlined,
                                    color: AppColors.textMuted, size: 14),
                                  const SizedBox(width: 4),
                                  Text('Tap exercise for demo & form check',
                                    style: Theme.of(context)
                                      .textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                    )),
                                ]),

                                const SizedBox(height: 12),

                                // ── Exercise List (Tappable) ──
                                ...exercises.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final ex  = entry.value;
                                  final muscleColor = _getMuscleColor(
                                    ex['muscle_group'] as String?);

                                  return GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                          ExerciseDetailScreen(
                                            exercise: ex)),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.only(
                                        bottom: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.background
                                          .withOpacity(0.5),
                                        borderRadius:
                                          BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.border
                                            .withOpacity(0.5)),
                                      ),
                                      child: Row(children: [

                                        // Exercise number
                                        Container(
                                          width: 32, height: 32,
                                          decoration: BoxDecoration(
                                            color: muscleColor
                                              .withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${idx + 1}',
                                              style: TextStyle(
                                                color: muscleColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                              )),
                                          ),
                                        ),

                                        const SizedBox(width: 12),

                                        // Exercise info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                            children: [
                                              Text(ex['name'],
                                                style: Theme.of(context)
                                                  .textTheme.bodyLarge
                                                  ?.copyWith(
                                                  fontWeight:
                                                    FontWeight.w600,
                                                )),
                                              const SizedBox(height: 3),
                                              Row(children: [
                                                Container(
                                                  padding:
                                                    const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 7,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: muscleColor
                                                      .withOpacity(0.12),
                                                    borderRadius:
                                                      BorderRadius
                                                        .circular(4),
                                                  ),
                                                  child: Text(
                                                    ex['muscle_group']
                                                      .toString()
                                                      .toUpperCase(),
                                                    style: TextStyle(
                                                      color: muscleColor,
                                                      fontSize: 9,
                                                      fontWeight:
                                                        FontWeight.w700,
                                                      letterSpacing: 0.5,
                                                    )),
                                                ),
                                              ]),
                                            ],
                                          ),
                                        ),

                                        // Sets x reps
                                        Column(
                                          crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${ex['sets']} × ${ex['reps']}',
                                              style: Theme.of(context)
                                                .textTheme.titleMedium
                                                ?.copyWith(
                                                color: AppColors.accent,
                                                fontWeight:
                                                  FontWeight.w700,
                                              )),
                                            Text(
                                              '${ex['rest_seconds']}s rest',
                                              style: Theme.of(context)
                                                .textTheme.bodySmall),
                                          ],
                                        ),

                                        const SizedBox(width: 8),

                                        // Arrow
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          color: AppColors.textMuted,
                                          size: 14),
                                      ]),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount:
                        (_plan!['sessions'] as List?)?.length ?? 0,
                    ),
                  ),

                  // ── Regenerate Button ────────────────────
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
}