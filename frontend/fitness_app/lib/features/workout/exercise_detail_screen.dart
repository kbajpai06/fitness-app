import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../../core/api_client.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> exercise;
  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin {
  // ── Animation ─────────────────────────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  // ── API data ──────────────────────────────────────────────
  String? _gifUrl;
  bool _gifLoading = true;
  List<String>? _apiInstructions;
  List<String> _secondaryMuscles = [];
  String? _description;
  String? _difficulty;
  String? _apiTarget;

  // ── Constants ─────────────────────────────────────────────
  static const Map<String, Color> _muscleColors = {
    'chest': Color(0xFFE85538),
    'back': Color(0xFF5A8CF5),
    'shoulders': Color(0xFFF5A623),
    'biceps': Color(0xFF4CAF82),
    'triceps': Color(0xFFC8F55A),
    'legs': Color(0xFF9B59B6),
    'glutes': Color(0xFFE91E8C),
    'core': Color(0xFF00BCD4),
    'full_body': Color(0xFFC8F55A),
  };

  static const _formCheckable = [
    'barbell squat',
    'bodyweight squat',
    'push up',
    'barbell bench press',
    'deadlift',
    'romanian deadlift',
    'pull up',
  ];

  // ── Getters ───────────────────────────────────────────────
  Color get _muscleColor {
    final muscle = (widget.exercise['muscle_group'] as String?) ?? 'chest';
    return _muscleColors[muscle] ?? AppColors.accent;
  }

  bool get _canFormCheck {
  final name = (widget.exercise['name'] as String).toLowerCase().trim();
  const checkable = [
    'squat', 'push up', 'pushup', 'push-up',
    'bench press', 'deadlift', 'pull up', 'pullup', 'pull-up',
  ];
  // ✅ Check if exercise name CONTAINS any checkable keyword
  return checkable.any((keyword) => name.contains(keyword));
}

  List<String> get _instructions {
    if (_apiInstructions != null && _apiInstructions!.isNotEmpty) {
      return _apiInstructions!;
    }
    final raw = widget.exercise['instructions'] as String? ?? '';
    if (raw.isEmpty) return ['No instructions available.'];
    return raw
        .split('.')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Color _difficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'beginner':
        return AppColors.success;
      case 'intermediate':
        return AppColors.warning;
      case 'advanced':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  // ── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _loadExerciseData();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Data Fetch ────────────────────────────────────────────
  Future<void> _loadExerciseData() async {
    final name = widget.exercise['name'] as String? ?? '';
    print('🔍 Fetching exercise data: $name');
    try {
      final data = await ApiClient.fetchExerciseData(name);
      print('📦 gif_url: ${data?['gif_url']}');
      if (mounted && data != null) {
        setState(() {
          _gifLoading = false;
          _gifUrl = data['gif_url'] as String?;

          // ✅ Fix: handle both List and String safely
          final rawInstr = data['instructions'];
          if (rawInstr is List && rawInstr.isNotEmpty) {
            _apiInstructions = rawInstr.map((e) => e.toString()).toList();
          }

          final rawSec = data['secondary'];
          _secondaryMuscles = rawSec is List
              ? rawSec.map((e) => e.toString()).toList()
              : [];

          final rawTarget = data['target'];
          _apiTarget = rawTarget is List
              ? (rawTarget.isNotEmpty ? rawTarget[0].toString() : null)
              : rawTarget?.toString();

          _description = data['description'] as String?;
          _difficulty = data['difficulty'] as String?;
        });
      } else if (mounted) {
        setState(() => _gifLoading = false);
      }
    } catch (e) {
      print('❌ Error fetching exercise data: $e');
      if (mounted) setState(() => _gifLoading = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final name = widget.exercise['name'] as String? ?? 'Exercise';
    final muscle = widget.exercise['muscle_group'] as String? ?? '';
    final sets = widget.exercise['sets'];
    final reps = widget.exercise['reps'];
    final rest = widget.exercise['rest_seconds'];
    final isCompound = widget.exercise['is_compound'] as bool? ?? false;
    final color = _muscleColor;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── App Bar + GIF ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildGifSection(color),
            ),
          ),

          // ── Main Content ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + muscle badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.3)),
                        ),
                        child: Text(
                          muscle.toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Movement type + difficulty badge
                  Row(
                    children: [
                      Text(
                        isCompound ? '🏋️ Compound' : '🎯 Isolation',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_difficulty != null) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _difficultyColor(
                              _difficulty!,
                            ).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _difficultyColor(
                                _difficulty!,
                              ).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            _difficulty!.toUpperCase(),
                            style: TextStyle(
                              color: _difficultyColor(_difficulty!),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Workout Prescription ───────────────────
                  _sectionLabel(context, 'WORKOUT PRESCRIPTION'),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          context,
                          '${sets ?? 3}',
                          'Sets',
                          Icons.repeat,
                          AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          context,
                          '${reps ?? '8-12'}',
                          'Reps',
                          Icons.fitness_center,
                          color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          context,
                          '${rest ?? 90}s',
                          'Rest',
                          Icons.timer_outlined,
                          AppColors.success,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Description (from API) ─────────────────
                  if (_description != null) ...[
                    _sectionLabel(context, 'ABOUT THIS EXERCISE'),
                    AppCard(
                      child: Text(
                        _description!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Muscles Worked ─────────────────────────
                  _sectionLabel(context, 'MUSCLES WORKED'),
                  _muscleGroupsCard(context, muscle, color),

                  const SizedBox(height: 28),

                  // ── How To Perform ─────────────────────────
                  _sectionLabel(context, 'HOW TO PERFORM'),
                  AppCard(
                    child: Column(
                      children: _instructions.asMap().entries.map((e) {
                        final step = e.key + 1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$step',
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        height: 1.5,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Pro Tips ───────────────────────────────
                  _sectionLabel(context, 'PRO TIPS'),
                  _tipsCard(context, muscle),

                  const SizedBox(height: 28),

                  // ── Form Check CTA ─────────────────────────
                  _formCheckCta(context, name, color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGETS
  // ═══════════════════════════════════════════════════════════

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── GIF Section ───────────────────────────────────────────
  Widget _buildGifSection(Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.15), AppColors.background],
        ),
      ),
      child: Stack(
        children: [
          // Grid background
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter(color: color)),
          ),

          // GIF / loading / fallback
          Center(child: _gifWidget(color)),

          // Bottom fade
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.background],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gifWidget(Color color) {
    if (_gifLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 60, bottom: 20),
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          color: AppColors.surface,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: color, strokeWidth: 2),
            const SizedBox(height: 12),
            Text(
              'Loading animation...',
              style: TextStyle(color: color.withOpacity(0.6), fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_gifUrl != null && _gifUrl!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 60, bottom: 20),
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: CachedNetworkImage(
            imageUrl: _gifUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: AppColors.surface,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerBox(width: 180, height: 160),
                  const SizedBox(height: 8),
                  Text(
                    'Loading...',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            errorWidget: (_, url, error) {
              print('❌ GIF load error: $url — $error');
              return _fallbackWidget(color);
            },
          ),
        ),
      );
    }

    return _fallbackWidget(color);
  }

  Widget _fallbackWidget(Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 60, bottom: 20),
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, color: color, size: 52),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.exercise['name'] as String? ?? '',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Muscle Groups Card ────────────────────────────────────
  Widget _muscleGroupsCard(BuildContext context, String muscle, Color color) {
    // Primary muscles — use API target or fallback map
    final primaryMap = {
      'chest': ['Chest / Pectorals'],
      'back': ['Lats', 'Rhomboids'],
      'shoulders': ['Deltoids'],
      'biceps': ['Biceps'],
      'triceps': ['Triceps'],
      'legs': ['Quads', 'Hamstrings'],
      'glutes': ['Glutes'],
      'core': ['Abs / Core'],
    };

    final primary = _apiTarget != null
        ? [_apiTarget!.replaceAll('_', ' ').toUpperCase()]
        : (primaryMap[muscle] ?? [muscle]);

    // Secondary — use API data if available, else fallback
    final secondaryMap = {
      'chest': ['Triceps', 'Front Delts'],
      'back': ['Biceps', 'Rear Delts'],
      'shoulders': ['Traps', 'Triceps'],
      'biceps': ['Brachialis', 'Forearms'],
      'triceps': ['Chest', 'Shoulders'],
      'legs': ['Glutes', 'Calves'],
      'glutes': ['Hamstrings', 'Core'],
      'core': ['Obliques', 'Lower Back'],
    };

    final secondary = _secondaryMuscles.isNotEmpty
        ? _secondaryMuscles
        : (secondaryMap[muscle] ?? []);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Primary',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: primary
                .map((m) => _musclePill(context, m, color, true))
                .toList(),
          ),

          if (secondary.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Secondary',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: secondary
                  .map((m) => _musclePill(context, m, color, false))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _musclePill(
    BuildContext context,
    String label,
    Color color,
    bool isPrimary,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isPrimary ? color.withOpacity(0.15) : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? color.withOpacity(0.4) : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isPrimary ? color : AppColors.textSecondary,
          fontSize: 13,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  // ── Pro Tips ──────────────────────────────────────────────
  Widget _tipsCard(BuildContext context, String muscle) {
    final tips = {
      'chest': [
        '🔑 Retract your shoulder blades before pressing',
        '📐 Keep elbows at 45-75°, not 90° flared out',
        '💨 Exhale on the press, inhale on the way down',
      ],
      'back': [
        '🔑 Lead with elbows, not your hands',
        '📐 Squeeze shoulder blades together at the top',
        '💨 Full stretch at bottom for better activation',
      ],
      'shoulders': [
        '🔑 Never press behind your neck — unsafe',
        '📐 Keep core braced to protect lower back',
        '💨 Control the eccentric (lowering) phase',
      ],
      'biceps': [
        '🔑 Keep elbows fixed — no swinging',
        '📐 Full range of motion beats heavy weight',
        '💨 Squeeze hard at the top of each rep',
      ],
      'triceps': [
        '🔑 Keep upper arms stationary throughout',
        '📐 Lock out fully at the bottom',
        '💨 Triceps = 2/3 of your arm size',
      ],
      'legs': [
        '🔑 Push through heels, not toes',
        '📐 Keep knees tracking over toes',
        '💨 Hit parallel or below for full activation',
      ],
      'glutes': [
        '🔑 Squeeze hard at the top of every rep',
        '📐 Drive hips up with a posterior tilt',
        '💨 Mind-muscle connection is everything here',
      ],
      'core': [
        '🔑 Breathe through reps — no breath holding',
        '📐 Quality over quantity, zero momentum',
        '💨 Brace like you\'re about to take a punch',
      ],
    };

    final muscleTips = tips[muscle] ?? tips['chest']!;
    return AppCard(
      child: Column(
        children: muscleTips
            .map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tip.substring(0, 2),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip.substring(2).trim(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Stat Card ─────────────────────────────────────────────
  Widget _statCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  // ── Form Check CTA ────────────────────────────────────────
  Widget _formCheckCta(BuildContext context, String name, Color color) {
    if (!_canFormCheck) {
      return AppCard(
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Live form check is available for squats, pushups, deadlifts & pull ups.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    return ScaleTransition(
      scale: _pulse,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    '📸 Form Check coming soon! Requires physical device.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live Form Check',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'AI analyses your $name form in real-time',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Grid Painter ──────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.06)
      ..strokeWidth = 1;
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}
