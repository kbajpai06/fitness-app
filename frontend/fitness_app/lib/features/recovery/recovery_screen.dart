import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  // Form values
  double _sleepHours    = 7.0;
  int    _sleepQuality  = 3;
  int    _soreness      = 2;
  int    _stress        = 2;
  int    _energy        = 3;
  bool   _isPain        = false;
  String _painLocation  = '';
  final  _notesCtrl     = TextEditingController();

  // State
  bool _submitting      = false;
  bool _submitted       = false;
  Map<String, dynamic>? _result;
  Map<String, dynamic>? _todayLog;
  bool _loadingToday    = true;

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    try {
      final data = await ApiClient.get('/recovery/today');
      if (mounted) {
        setState(() {
          _todayLog    = data;
          _loadingToday = false;
          if (data['logged_today'] == true) {
            _submitted = true;
            _result    = data;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingToday = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final body = {
        'sleep_hours':    _sleepHours,
        'sleep_quality':  _sleepQuality,
        'soreness_level': _soreness,
        'stress_level':   _stress,
        'energy_level':   _energy,
        'is_pain':        _isPain,
        if (_isPain && _painLocation.isNotEmpty)
          'pain_location': _painLocation,
        if (_notesCtrl.text.isNotEmpty)
          'notes': _notesCtrl.text,
      };
      final res = await ApiClient.post('/recovery/log', body);
      if (mounted) {
        setState(() {
          _result    = res;
          _submitted = true;
          _submitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating),
        );
        setState(() => _submitting = false);
      }
    }
  }

  // ── Score color ────────────────────────────────────────────
  Color _scoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.accent;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingToday) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent)));
    }

    return Scaffold(
      body: _submitted ? _resultView() : _formView(),
    );
  }

  // ══════════════════════════════════════════════════════════
  // FORM VIEW
  // ══════════════════════════════════════════════════════════

  Widget _formView() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recovery\nCheck-in',
                  style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 8),
                Text('Takes 30 seconds. Helps your AI coach adapt your plan.',
                  style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),

        // Sleep hours
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Text('😴', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Text('Sleep',
                          style: Theme.of(context).textTheme.titleMedium),
                      ]),
                      Text('${_sleepHours.toStringAsFixed(1)}h',
                        style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(color: AppColors.accent)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: AppColors.surfaceHigh,
                      thumbColor: AppColors.accent,
                      overlayColor: AppColors.accent.withOpacity(0.2),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: _sleepHours,
                      min: 3, max: 12, divisions: 18,
                      onChanged: (v) => setState(() => _sleepHours = v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('3h', style: Theme.of(context).textTheme.bodySmall),
                      Text('12h', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Sleep quality',
                    style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  _ratingRow(
                    value: _sleepQuality,
                    labels: ['Poor', 'Bad', 'Ok', 'Good', 'Great'],
                    onChanged: (v) => setState(() => _sleepQuality = v),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Soreness
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('💪', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text('Muscle Soreness',
                      style: Theme.of(context).textTheme.titleMedium),
                  ]),
                  const SizedBox(height: 6),
                  Text('How sore are your muscles today?',
                    style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 14),
                  _ratingRow(
                    value: _soreness,
                    labels: ['None', 'Mild', 'Moderate', 'High', 'Very High'],
                    onChanged: (v) => setState(() => _soreness = v),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Stress & Energy
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Text('🧠', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text('Stress',
                          style: Theme.of(context).textTheme.titleMedium),
                      ]),
                      const SizedBox(height: 14),
                      _compactRating(
                        value: _stress,
                        onChanged: (v) => setState(() => _stress = v),
                        lowLabel: 'Low',
                        highLabel: 'High',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Text('⚡', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text('Energy',
                          style: Theme.of(context).textTheme.titleMedium),
                      ]),
                      const SizedBox(height: 14),
                      _compactRating(
                        value: _energy,
                        onChanged: (v) => setState(() => _energy = v),
                        lowLabel: 'Low',
                        highLabel: 'High',
                      ),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Pain toggle
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Text('⚠️', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pain (not soreness)',
                              style: Theme.of(context).textTheme.titleMedium),
                            Text('Sharp, joint, or acute pain',
                              style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ]),
                      Switch(
                        value: _isPain,
                        onChanged: (v) => setState(() => _isPain = v),
                        activeColor: AppColors.error,
                        activeTrackColor: AppColors.error.withOpacity(0.3),
                      ),
                    ],
                  ),
                  if (_isPain) ...[
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (v) => _painLocation = v,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Where? e.g. left knee, lower back',
                        prefixIcon: Icon(Icons.location_on_outlined,
                          color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Notes
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('📝', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Text('Notes (optional)',
                      style: Theme.of(context).textTheme.titleMedium),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Anything else? e.g. skipped dinner, felt dizzy...',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Submit
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
            child: AppButton(
              label: 'Get AI Recovery Advice',
              onPressed: _submit,
              isLoading: _submitting,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════
  // RESULT VIEW
  // ══════════════════════════════════════════════════════════

  Widget _resultView() {
    final score = _result?['recovery_score'] as int? ?? 0;
    final rec   = _result?['training_recommendation']
                  as Map<String, dynamic>?  ?? {};
    final advice= _result?['ai_advice'] as String? ?? '';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recovery\nReport',
                  style: Theme.of(context).textTheme.displayMedium),
                const SizedBox(height: 32),

                // Score circle
                Center(
                  child: Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _scoreColor(score), width: 4),
                      color: _scoreColor(score).withOpacity(0.1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$score',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: _scoreColor(score),
                          )),
                        Text('/ 100',
                          style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Training recommendation
                AppCard(
                  color: _scoreColor(score).withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec['label'] ?? '',
                        style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(color: _scoreColor(score))),
                      const SizedBox(height: 8),
                      Text(rec['message'] ?? '',
                        style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(height: 1.5)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Today's stats recap
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("TODAY'S STATS",
                        style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(letterSpacing: 1.5,
                            fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _recapStat('😴', 'Sleep',
                            '${_sleepHours.toStringAsFixed(1)}h'),
                          _recapStat('💪', 'Soreness',
                            '$_soreness/5'),
                          _recapStat('🧠', 'Stress',
                            '$_stress/5'),
                          _recapStat('⚡', 'Energy',
                            '$_energy/5'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // AI Advice
                if (advice.isNotEmpty) ...[
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.accentDim,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.bolt,
                              color: AppColors.accent, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Text('AI Coach Advice',
                            style: Theme.of(context).textTheme.titleMedium),
                        ]),
                        const SizedBox(height: 14),
                        Text(advice,
                          style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(height: 1.6)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Log again tomorrow
                AppCard(
                  child: Row(children: [
                    const Icon(Icons.check_circle,
                      color: AppColors.success, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Check-in logged!',
                            style: Theme.of(context).textTheme.titleMedium),
                          Text('Come back tomorrow morning for best results.',
                            style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────

  Widget _recapStat(String emoji, String label, String value) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 4),
      Text(value,
        style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(color: AppColors.textPrimary)),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }

  Widget _ratingRow({
    required int value,
    required List<String> labels,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (i) {
            final isSelected = value == i + 1;
            return GestureDetector(
              onTap: () => onChanged(i + 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52, height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                    ? AppColors.accent
                    : AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                      ? AppColors.accent
                      : AppColors.border),
                ),
                child: Center(
                  child: Text('${i + 1}',
                    style: TextStyle(
                      color: isSelected
                        ? AppColors.background
                        : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    )),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(labels[0],
              style: Theme.of(context).textTheme.bodySmall),
            Text(labels[4],
              style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }

  Widget _compactRating({
    required int value,
    required ValueChanged<int> onChanged,
    required String lowLabel,
    required String highLabel,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (i) {
            final isSelected = value == i + 1;
            return GestureDetector(
              onTap: () => onChanged(i + 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                    ? AppColors.accent
                    : AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('${i + 1}',
                    style: TextStyle(
                      color: isSelected
                        ? AppColors.background
                        : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    )),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(lowLabel,
              style: Theme.of(context).textTheme.bodySmall),
            Text(highLabel,
              style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}