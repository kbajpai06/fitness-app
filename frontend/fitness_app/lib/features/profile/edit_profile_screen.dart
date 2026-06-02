import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profile;
  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _weightCtrl  = TextEditingController();
  final _heightCtrl  = TextEditingController();
  final _ageCtrl     = TextEditingController();

  String? _goal;
  String? _experience;
  String? _gender;
  int    _daysPerWeek   = 3;
  double _monthlyBudget = 3000;
  bool   _isVegetarian  = false;
  bool   _saving        = false;

  final _goals = const [
    {'value': 'muscle_gain',     'label': 'Build Muscle',    'emoji': '💪'},
    {'value': 'weight_loss',     'label': 'Lose Weight',     'emoji': '🔥'},
    {'value': 'general_fitness', 'label': 'Stay Fit',        'emoji': '⚡'},
    {'value': 'endurance',       'label': 'Build Endurance', 'emoji': '🏃'},
    {'value': 'rehabilitation',  'label': 'Recover',         'emoji': '🧘'},
  ];

  final _levels = const [
    {'value': 'beginner',     'label': 'Beginner',     'emoji': '🌱'},
    {'value': 'intermediate', 'label': 'Intermediate', 'emoji': '⚡'},
    {'value': 'advanced',     'label': 'Advanced',     'emoji': '🔥'},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _weightCtrl.text  = '${p['weight_kg'] ?? ''}';
    _heightCtrl.text  = '${p['height_cm'] ?? ''}';
    _ageCtrl.text     = '${p['age'] ?? ''}';
    _goal             = p['fitness_goal'];
    _experience       = p['experience_level'];
    _gender           = p['gender'];
    _daysPerWeek      = p['days_per_week'] ?? 3;
    _monthlyBudget    = (p['monthly_food_budget'] ?? 3000).toDouble();
    _isVegetarian     = p['is_vegetarian'] ?? false;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ApiClient.put('/users/profile', {
        if (_goal != null)        'fitness_goal':        _goal,
        if (_experience != null)  'experience_level':    _experience,
        if (_gender != null)      'gender':              _gender,
        if (_ageCtrl.text.isNotEmpty)
          'age':                  int.tryParse(_ageCtrl.text),
        if (_weightCtrl.text.isNotEmpty)
          'weight_kg':            double.tryParse(_weightCtrl.text),
        if (_heightCtrl.text.isNotEmpty)
          'height_cm':            double.tryParse(_heightCtrl.text),
        'days_per_week':          _daysPerWeek,
        'monthly_food_budget':    _monthlyBudget,
        'is_vegetarian':          _isVegetarian,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated! ✅'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating));
        Navigator.pop(context, true); // return true = refresh needed
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Body Stats ─────────────────────────────────
            _sectionLabel('BODY STATS'),
            AppCard(
              child: Column(children: [
                Row(children: [
                  Expanded(child: _inputField(
                    controller: _ageCtrl,
                    label: 'Age',
                    suffix: 'yrs',
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _inputField(
                    controller: _weightCtrl,
                    label: 'Weight',
                    suffix: 'kg',
                  )),
                  const SizedBox(width: 16),
                  Expanded(child: _inputField(
                    controller: _heightCtrl,
                    label: 'Height',
                    suffix: 'cm',
                  )),
                ]),
                const SizedBox(height: 16),
                // Gender
                Row(children: [
                  Expanded(child: _genderBtn('male',   '♂️ Male')),
                  const SizedBox(width: 12),
                  Expanded(child: _genderBtn('female', '♀️ Female')),
                ]),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Fitness Goal ───────────────────────────────
            _sectionLabel('FITNESS GOAL'),
            Wrap(
              spacing: 10, runSpacing: 10,
              children: _goals.map((g) {
                final isSelected = _goal == g['value'];
                return GestureDetector(
                  onTap: () => setState(() => _goal = g['value']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                        ? AppColors.accentDim
                        : AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isSelected
                          ? AppColors.accent
                          : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text('${g['emoji']} ${g['label']}',
                      style: TextStyle(
                        color: isSelected
                          ? AppColors.accent
                          : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      )),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Experience ─────────────────────────────────
            _sectionLabel('EXPERIENCE LEVEL'),
            Row(
              children: _levels.map((l) {
                final isSelected = _experience == l['value'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _experience = l['value']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(
                        right: l['value'] != 'advanced' ? 10 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                          ? AppColors.accentDim
                          : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                            ? AppColors.accent
                            : AppColors.border,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(children: [
                        Text(l['emoji']!,
                          style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(l['label']!,
                          style: TextStyle(
                            color: isSelected
                              ? AppColors.accent
                              : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          )),
                      ]),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Schedule ───────────────────────────────────
            _sectionLabel('WORKOUT DAYS / WEEK'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                final day = i + 2;
                final isSelected = _daysPerWeek == day;
                return GestureDetector(
                  onTap: () => setState(() => _daysPerWeek = day),
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
                    child: Center(child: Text('$day',
                      style: TextStyle(
                        color: isSelected
                          ? AppColors.background
                          : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ))),
                  ),
                );
              }),
            ),

            const SizedBox(height: 24),

            // ── Budget ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionLabel('MONTHLY FOOD BUDGET', margin: false),
                Text('₹${_monthlyBudget.round()}',
                  style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: AppColors.accent)),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.accent,
                inactiveTrackColor: AppColors.surfaceHigh,
                thumbColor: AppColors.accent,
                overlayColor: AppColors.accent.withOpacity(0.2),
                trackHeight: 3,
              ),
              child: Slider(
                value: _monthlyBudget,
                min: 1000, max: 10000, divisions: 18,
                onChanged: (v) => setState(() => _monthlyBudget = v),
              ),
            ),

            const SizedBox(height: 16),

            // ── Vegetarian ─────────────────────────────────
            AppCard(
              child: Row(children: [
                const Text('🥗', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vegetarian',
                      style: Theme.of(context).textTheme.titleMedium),
                    Text('Excludes meat from meal plans',
                      style: Theme.of(context).textTheme.bodySmall),
                  ],
                )),
                Switch(
                  value: _isVegetarian,
                  onChanged: (v) => setState(() => _isVegetarian = v),
                  activeColor: AppColors.accent,
                  activeTrackColor: AppColors.accentDim,
                ),
              ]),
            ),

            const SizedBox(height: 32),

            AppButton(label: 'Save Changes', onPressed: _save,
              isLoading: _saving),

            const SizedBox(height: 16),

            // Regenerate plans notice
            AppCard(
              color: AppColors.accentDim,
              child: Row(children: [
                const Icon(Icons.info_outline,
                  color: AppColors.accent, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'After saving, regenerate your workout & diet plans '
                  'from the Workout and Diet tabs.',
                  style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.accent),
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, {bool margin = true}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, top: margin ? 0 : 0),
      child: Text(text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          letterSpacing: 1.5, fontWeight: FontWeight.w600)),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: const TextStyle(
              color: AppColors.textMuted, fontSize: 12),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _genderBtn(String value, String label) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentDim : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(child: Text(label,
          style: TextStyle(
            color: isSelected
              ? AppColors.accent
              : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ))),
      ),
    );
  }
}