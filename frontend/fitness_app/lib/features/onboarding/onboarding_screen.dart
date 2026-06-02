import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentPage = 0;
  bool _loading = false;

  // ── Collected Data ───────────────────────────────────────────
  String? _goal;
  String? _experience;
  String? _gender;
  final _ageCtrl    = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  int    _daysPerWeek    = 3;
  double _monthlyBudget  = 3000;
  bool   _isVegetarian   = false;

  // ── Navigation ───────────────────────────────────────────────
  void _next() {
    if (_currentPage < 4) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0: return _goal != null;
      case 1: return _experience != null;
      case 2: return _gender != null &&
                     _ageCtrl.text.isNotEmpty &&
                     _weightCtrl.text.isNotEmpty &&
                     _heightCtrl.text.isNotEmpty;
      case 3: return true;
      default: return false;
    }
  }

  // ── Final Submit ─────────────────────────────────────────────
  Future<void> _finish() async {
    setState(() => _loading = true);
    try {
      // Step 1 — save profile
      await ApiClient.put('/users/profile', {
        'fitness_goal':       _goal,
        'experience_level':   _experience,
        'gender':             _gender,
        'age':                int.tryParse(_ageCtrl.text) ?? 22,
        'weight_kg':          double.tryParse(_weightCtrl.text) ?? 70,
        'height_cm':          double.tryParse(_heightCtrl.text) ?? 170,
        'days_per_week':      _daysPerWeek,
        'monthly_food_budget':_monthlyBudget,
        'is_vegetarian':      _isVegetarian,
        'workout_duration_mins': 45,
      });

      // Step 2 — generate workout plan
      await ApiClient.post('/workout/generate', {});

      // Step 3 — generate diet plan
      await ApiClient.post('/diet/generate', {});

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating),
        );
        setState(() => _loading = false);
      }
    }
  }

  // ── Progress Bar ─────────────────────────────────────────────
  Widget _progressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(5, (i) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 3,
              decoration: BoxDecoration(
                color: i <= _currentPage
                  ? AppColors.accent
                  : AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Progress + back
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    GestureDetector(
                      onTap: _back,
                      child: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: AppColors.textSecondary),
                    )
                  else
                    const SizedBox(width: 20),
                  const SizedBox(width: 16),
                  Expanded(child: _progressBar()),
                  const SizedBox(width: 16),
                  Text('${_currentPage + 1}/5',
                    style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _GoalPage(
                    selected: _goal,
                    onSelect: (v) => setState(() => _goal = v),
                  ),
                  _ExperiencePage(
                    selected: _experience,
                    onSelect: (v) => setState(() => _experience = v),
                  ),
                  _BodyStatsPage(
                    gender: _gender,
                    ageCtrl: _ageCtrl,
                    weightCtrl: _weightCtrl,
                    heightCtrl: _heightCtrl,
                    onGenderSelect: (v) => setState(() => _gender = v),
                  ),
                  _SchedulePage(
                    daysPerWeek: _daysPerWeek,
                    monthlyBudget: _monthlyBudget,
                    isVegetarian: _isVegetarian,
                    onDaysChanged: (v) => setState(() => _daysPerWeek = v),
                    onBudgetChanged: (v) => setState(() => _monthlyBudget = v),
                    onVegChanged: (v) => setState(() => _isVegetarian = v),
                  ),
                  _GeneratingPage(loading: _loading),
                ],
              ),
            ),

            // CTA Button
            if (_currentPage < 4)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: AppButton(
                  label: _currentPage == 3 ? 'Build My Plan 🚀' : 'Continue',
                  onPressed: _canProceed() ? (_currentPage == 3 ? _finish : _next) : null,
                  isLoading: _loading,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAGE 1 — Goal Selection
// ═══════════════════════════════════════════════════════════════

class _GoalPage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _GoalPage({required this.selected, required this.onSelect});

  final _goals = const [
    {'value': 'muscle_gain',      'label': 'Build Muscle',    'emoji': '💪', 'desc': 'Gain strength & size'},
    {'value': 'weight_loss',      'label': 'Lose Weight',     'emoji': '🔥', 'desc': 'Burn fat, get lean'},
    {'value': 'general_fitness',  'label': 'Stay Fit',        'emoji': '⚡', 'desc': 'Overall health & energy'},
    {'value': 'endurance',        'label': 'Build Endurance', 'emoji': '🏃', 'desc': 'Stamina & cardio'},
    {'value': 'rehabilitation',   'label': 'Recover & Rehab', 'emoji': '🧘', 'desc': 'Injury recovery'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What is your\nmain goal?',
            style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text('We\'ll personalize everything around this.',
            style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: _goals.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final g = _goals[i];
                final isSelected = selected == g['value'];
                return GestureDetector(
                  onTap: () => onSelect(g['value']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected
                        ? AppColors.accentDim
                        : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                          ? AppColors.accent
                          : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(children: [
                      Text(g['emoji']!,
                        style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g['label']!,
                              style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                color: isSelected
                                  ? AppColors.accent
                                  : AppColors.textPrimary,
                              )),
                            Text(g['desc']!,
                              style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                          color: AppColors.accent, size: 22),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAGE 2 — Experience Level
// ═══════════════════════════════════════════════════════════════

class _ExperiencePage extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _ExperiencePage({required this.selected, required this.onSelect});

  final _levels = const [
    {
      'value': 'beginner',
      'label': 'Beginner',
      'emoji': '🌱',
      'desc': 'New to fitness or just getting back',
      'detail': 'Safe, gradual progression. Form-first approach.',
    },
    {
      'value': 'intermediate',
      'label': 'Intermediate',
      'emoji': '⚡',
      'desc': '1–3 years of consistent training',
      'detail': 'Progressive overload. Structured splits.',
    },
    {
      'value': 'advanced',
      'label': 'Advanced',
      'emoji': '🔥',
      'desc': '3+ years, comfortable with heavy lifts',
      'detail': 'High intensity. Periodization. Complex movements.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your experience\nlevel?',
            style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text('Be honest — this keeps your workouts safe & effective.',
            style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          ..._levels.map((l) {
            final isSelected = selected == l['value'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => onSelect(l['value']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected
                      ? AppColors.accentDim
                      : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                        ? AppColors.accent
                        : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(children: [
                    Text(l['emoji']!,
                      style: const TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l['label']!,
                            style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                              color: isSelected
                                ? AppColors.accent
                                : AppColors.textPrimary,
                            )),
                          const SizedBox(height: 2),
                          Text(l['desc']!,
                            style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 4),
                          Text(l['detail']!,
                            style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(Icons.check_circle,
                        color: AppColors.accent, size: 22),
                  ]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAGE 3 — Body Stats
// ═══════════════════════════════════════════════════════════════

class _BodyStatsPage extends StatelessWidget {
  final String? gender;
  final TextEditingController ageCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController heightCtrl;
  final ValueChanged<String> onGenderSelect;

  const _BodyStatsPage({
    required this.gender,
    required this.ageCtrl,
    required this.weightCtrl,
    required this.heightCtrl,
    required this.onGenderSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your body\nstats',
            style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text('Used to calculate your exact calorie & macro targets.',
            style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),

          // Gender
          Text('GENDER',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 1.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _genderBtn(context, 'male',   '♂️ Male')),
            const SizedBox(width: 12),
            Expanded(child: _genderBtn(context, 'female', '♀️ Female')),
          ]),

          const SizedBox(height: 28),

          // Age
          Text('AGE',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 1.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: ageCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'e.g. 22',
              suffixText: 'years',
              suffixStyle: TextStyle(color: AppColors.textMuted),
            ),
          ),

          const SizedBox(height: 24),

          // Weight & Height side by side
          Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WEIGHT',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: weightCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: '70',
                      suffixText: 'kg',
                      suffixStyle: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HEIGHT',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: heightCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      hintText: '175',
                      suffixText: 'cm',
                      suffixStyle: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _genderBtn(BuildContext context, String value, String label) {
    final isSelected = gender == value;
    return GestureDetector(
      onTap: () => onGenderSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentDim : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(label,
            style: TextStyle(
              color: isSelected
                ? AppColors.accent
                : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            )),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAGE 4 — Schedule & Budget
// ═══════════════════════════════════════════════════════════════

class _SchedulePage extends StatelessWidget {
  final int daysPerWeek;
  final double monthlyBudget;
  final bool isVegetarian;
  final ValueChanged<int> onDaysChanged;
  final ValueChanged<double> onBudgetChanged;
  final ValueChanged<bool> onVegChanged;

  const _SchedulePage({
    required this.daysPerWeek,
    required this.monthlyBudget,
    required this.isVegetarian,
    required this.onDaysChanged,
    required this.onBudgetChanged,
    required this.onVegChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schedule &\npreferences',
            style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text('We\'ll build your plan around your life.',
            style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 36),

          // Days per week
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('WORKOUT DAYS / WEEK',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              Text('$daysPerWeek days',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) {
              final day = i + 2;
              final isSelected = daysPerWeek == day;
              return GestureDetector(
                onTap: () => onDaysChanged(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                      ? AppColors.accent
                      : AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                        ? AppColors.accent
                        : AppColors.border),
                  ),
                  child: Center(
                    child: Text('$day',
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

          const SizedBox(height: 36),

          // Monthly food budget
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('MONTHLY FOOD BUDGET',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.5, fontWeight: FontWeight.w600)),
              Text('₹${monthlyBudget.round()}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.surfaceHigh,
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withOpacity(0.2),
              trackHeight: 3,
            ),
            child: Slider(
              value: monthlyBudget,
              min: 1000,
              max: 10000,
              divisions: 18,
              onChanged: onBudgetChanged,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹1,000', style: Theme.of(context).textTheme.bodySmall),
              Text('₹10,000', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),

          const SizedBox(height: 36),

          // Vegetarian toggle
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              const Text('🥗', style: TextStyle(fontSize: 28)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vegetarian',
                      style: Theme.of(context).textTheme.titleMedium),
                    Text('No meat in your meal plan',
                      style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Switch(
                value: isVegetarian,
                onChanged: onVegChanged,
                activeColor: AppColors.accent,
                activeTrackColor: AppColors.accentDim,
              ),
            ]),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PAGE 5 — Generating
// ═══════════════════════════════════════════════════════════════

class _GeneratingPage extends StatelessWidget {
  final bool loading;
  const _GeneratingPage({required this.loading});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (loading) ...[
            const SizedBox(
              width: 64, height: 64,
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 32),
            Text('Building your plan...',
              style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text('Generating personalized workout\nand 7-day meal plan',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
            const SizedBox(height: 32),
            _buildingStep(context, '✅ Profile saved'),
            _buildingStep(context, '🏋️ Creating workout split'),
            _buildingStep(context, '🍱 Building Indian meal plan'),
            _buildingStep(context, '🤖 Calibrating AI coach'),
          ] else ...[
            const Text('🚀', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 24),
            Text('You\'re all set!',
              style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 12),
            Text('Your personalized fitness plan is ready.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Widget _buildingStep(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}