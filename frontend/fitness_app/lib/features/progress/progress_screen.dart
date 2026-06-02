import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _summary;
  List<dynamic> _history = [];
  bool _loading = true;

  // Log form
  final _weightCtrl  = TextEditingController();
  final _waistCtrl   = TextEditingController();
  final _chestCtrl   = TextEditingController();
  final _armsCtrl    = TextEditingController();
  final _notesCtrl   = TextEditingController();
  bool _logging      = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiClient.get('/progress/summary'),
        ApiClient.get('/progress/history?days=30'),
      ]);
      if (mounted) {
        setState(() {
          _summary = results[0];
          _history = results[1]['logs'] ?? [];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logProgress() async {
    if (_weightCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter at least your weight.'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _logging = true);
    try {
      final body = <String, dynamic>{};
      if (_weightCtrl.text.isNotEmpty)
        body['weight_kg']  = double.parse(_weightCtrl.text);
      if (_waistCtrl.text.isNotEmpty)
        body['waist_cm']   = double.parse(_waistCtrl.text);
      if (_chestCtrl.text.isNotEmpty)
        body['chest_cm']   = double.parse(_chestCtrl.text);
      if (_armsCtrl.text.isNotEmpty)
        body['arms_cm']    = double.parse(_armsCtrl.text);
      if (_notesCtrl.text.isNotEmpty)
        body['notes']      = _notesCtrl.text;

      await ApiClient.post('/progress/log', body);

      // Clear fields
      _weightCtrl.clear();
      _waistCtrl.clear();
      _chestCtrl.clear();
      _armsCtrl.clear();
      _notesCtrl.clear();

      await _loadData();

      if (mounted) {
        _tabCtrl.animateTo(1); // switch to history tab
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress logged! 💪'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _logging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.accent))
        : NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Progress',
                        style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 4),
                      Text(
                        _summary?['days_tracked'] != null
                          ? 'Tracking for ${_summary!['days_tracked']} days'
                          : 'Start logging to see trends',
                        style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 24),

                      // Summary cards
                      if (_summary?['current'] != null) ...[
                        _summaryRow(),
                        const SizedBox(height: 24),
                      ],

                      // Tabs
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TabBar(
                          controller: _tabCtrl,
                          indicator: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: AppColors.background,
                          unselectedLabelColor: AppColors.textSecondary,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                          tabs: const [
                            Tab(text: 'Log Today'),
                            Tab(text: 'History'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                _logTab(),
                _historyTab(),
              ],
            ),
          ),
    );
  }

  // ── Summary Row ────────────────────────────────────────────

  Widget _summaryRow() {
    final current = _summary!['current'] as Map<String, dynamic>;
    final changes = _summary!['changes'] as Map<String, dynamic>? ?? {};

    return Row(children: [
      Expanded(child: _summaryCard(
        label: 'Weight',
        value: '${current['weight_kg'] ?? '--'}',
        unit: 'kg',
        change: changes['weight_kg'],
        lowerIsBetter: true,
      )),
      const SizedBox(width: 12),
      Expanded(child: _summaryCard(
        label: 'Waist',
        value: '${current['waist_cm'] ?? '--'}',
        unit: 'cm',
        change: changes['waist_cm'],
        lowerIsBetter: true,
      )),
      const SizedBox(width: 12),
      Expanded(child: _summaryCard(
        label: 'Arms',
        value: '${current['arms_cm'] ?? '--'}',
        unit: 'cm',
        change: changes['arms_cm'],
        lowerIsBetter: false,
      )),
    ]);
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required String unit,
    required dynamic change,
    required bool lowerIsBetter,
  }) {
    Color? changeColor;
    String changeText = '';

    if (change != null && change != 0.0) {
      final isGood = lowerIsBetter ? change < 0 : change > 0;
      changeColor = isGood ? AppColors.success : AppColors.error;
      changeText  = '${change > 0 ? '+' : ''}$change';
    }

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value,
            style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700)),
          Text(unit, style: Theme.of(context).textTheme.bodySmall),
          if (changeText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(changeText,
              style: TextStyle(
                color: changeColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              )),
          ],
        ],
      ),
    );
  }

  // ── Log Tab ────────────────────────────────────────────────

  Widget _logTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("TODAY'S MEASUREMENTS",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 1.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),

          // Weight — required
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('⚖️', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Text('Weight *',
                    style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  Text('required',
                    style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.accent)),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'e.g. 70.5',
                    suffixText: 'kg',
                    suffixStyle: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text('BODY MEASUREMENTS (optional)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 1.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          // Measurements grid
          Row(children: [
            Expanded(child: _measureField(
              controller: _waistCtrl,
              emoji: '📏',
              label: 'Waist',
              hint: '80',
            )),
            const SizedBox(width: 12),
            Expanded(child: _measureField(
              controller: _chestCtrl,
              emoji: '🫁',
              label: 'Chest',
              hint: '95',
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _measureField(
              controller: _armsCtrl,
              emoji: '💪',
              label: 'Arms',
              hint: '33',
            )),
            const SizedBox(width: 12),
            const Expanded(child: SizedBox()),
          ]),

          const SizedBox(height: 12),

          // Notes
          AppCard(
            child: TextField(
              controller: _notesCtrl,
              maxLines: 2,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: '📝 Notes... e.g. after workout, morning fasted',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(height: 24),

          AppButton(
            label: 'Log Progress',
            onPressed: _logProgress,
            isLoading: _logging,
          ),
        ],
      ),
    );
  }

  Widget _measureField({
    required TextEditingController controller,
    required String emoji,
    required String label,
    required String hint,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(label,
              style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.textPrimary)),
          ]),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 18,
              fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              suffixText: 'cm',
              suffixStyle: const TextStyle(
                color: AppColors.textMuted, fontSize: 12),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  // ── History Tab ────────────────────────────────────────────

  Widget _historyTab() {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📊', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No logs yet',
              style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Start logging to see your progress here.',
              style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: _history.length,
      itemBuilder: (context, i) {
        final log = _history[i];
        final date = DateTime.tryParse(log['logged_at'] ?? '');
        final dateStr = date != null
          ? '${date.day}/${date.month}/${date.year}'
          : '--';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.accentDim,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        date != null ? '${date.day}' : '--',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        )),
                      Text(
                        date != null
                          ? _monthName(date.month)
                          : '',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Stats
                Expanded(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (log['weight_kg'] != null)
                        _histStat('⚖️', '${log['weight_kg']}kg'),
                      if (log['waist_cm'] != null)
                        _histStat('📏', '${log['waist_cm']}cm waist'),
                      if (log['chest_cm'] != null)
                        _histStat('🫁', '${log['chest_cm']}cm chest'),
                      if (log['arms_cm'] != null)
                        _histStat('💪', '${log['arms_cm']}cm arms'),
                      if (log['notes'] != null && log['notes'] != '')
                        _histStat('📝', log['notes']),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _histStat(String emoji, String value) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(emoji, style: const TextStyle(fontSize: 14)),
      const SizedBox(width: 4),
      Text(value, style: Theme.of(context).textTheme.bodyMedium
        ?.copyWith(color: AppColors.textPrimary)),
    ]);
  }

  String _monthName(int month) {
    const months = ['JAN','FEB','MAR','APR','MAY','JUN',
                    'JUL','AUG','SEP','OCT','NOV','DEC'];
    return months[month - 1];
  }
}