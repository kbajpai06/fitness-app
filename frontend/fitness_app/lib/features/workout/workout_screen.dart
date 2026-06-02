import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

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
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Workout', style: Theme.of(context).textTheme.displayMedium),
                        const SizedBox(height: 4),
                        Text(_plan != null ? _plan!['name'] ?? '' : 'No plan yet',
                          style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                if (_plan == null)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset('assets/animations/empty_workout.json', width: 200, height: 200,repeat: true),
                        const SizedBox(height: 16),
                        Text('No workout plan generated yet.',
                          style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text('Generate a personalized workout plan based on your profile and goals.',
                          style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 32),
                        AppButton(
                          label: 'Generate Plan',
                          onPressed: _generatePlan,
                          isLoading: _generating,
                          icon: Icons.auto_awesome,
                        ),
                      ],
                    )
                  )
                
                else ...[
                  // Sessions
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final sessions = (_plan!['sessions'] as List?) ?? [];
                        if (i >= sessions.length) return null;
                        final session = sessions[i];
                        final dayName = _days[session['day_of_week'] as int];
                        final exercises = (session['exercises'] as List?) ?? [];
                        final isToday = session['day_of_week'] == DateTime.now().weekday - 1;

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                          child: AppCard(
                            color: isToday ? AppColors.accentDim : null,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isToday
                                            ? AppColors.accent
                                            : AppColors.surfaceHigh,
                                          borderRadius: BorderRadius.circular(8),
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
                                        style: Theme.of(context).textTheme.titleLarge),
                                    ]),
                                    Text('${session['duration_mins']} min',
                                      style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 12),
                                ...exercises.map((ex) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Row(children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(ex['name'],
                                            style: Theme.of(context).textTheme.bodyLarge),
                                          const SizedBox(height: 2),
                                          Text(ex['muscle_group'],
                                            style: Theme.of(context).textTheme.bodySmall),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('${ex['sets']} × ${ex['reps']}',
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            color: AppColors.accent)),
                                        Text('${ex['rest_seconds']}s rest',
                                          style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                  ]),
                                )),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: (_plan!['sessions'] as List?)?.length ?? 0,
                    ),
                  ),

                  // Regenerate button
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