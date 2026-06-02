import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../recovery/recovery_screen.dart';
import '../progress/progress_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiClient.get('/users/profile');
      if (mounted)
        setState(() {
          _profile = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await ApiClient.clearToken();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }

    final name = _profile?['full_name'] ?? 'User';
    final email = _profile?['email'] ?? '';
    final goal =
        (_profile?['fitness_goal'] as String?)
            ?.replaceAll('_', ' ')
            .toUpperCase() ??
        'NOT SET';
    final level =
        (_profile?['experience_level'] as String?)?.toUpperCase() ?? 'BEGINNER';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 32),

                  // Avatar + name
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.accentDim,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            email,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _badge(goal, AppColors.accent),
                              const SizedBox(width: 8),
                              _badge(level, AppColors.textSecondary),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Body stats
                  Text(
                    "BODY STATS",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  AppCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem(
                          context,
                          'Weight',
                          '${_profile?['weight_kg'] ?? '--'}',
                          'kg',
                        ),
                        _divider(),
                        _statItem(
                          context,
                          'Height',
                          '${_profile?['height_cm'] ?? '--'}',
                          'cm',
                        ),
                        _divider(),
                        _statItem(
                          context,
                          'Days/Week',
                          '${_profile?['days_per_week'] ?? '--'}',
                          'days',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Settings
                  Text(
                    "SETTINGS",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  AppCard(
                    child: Column(
                      children: [
                        _settingRow(
                          context,
                          Icons.person_outline,
                          'Edit Profile',
                          () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditProfileScreen(profile: _profile ?? {}),
                              ),
                            );
                            if (updated == true)
                              _loadProfile(); // refresh on return
                          },
                        ),
                        const Divider(),
                        _settingRow(
                          context,
                          Icons.restaurant_outlined,
                          'Diet Preferences',
                          () {},
                        ),
                        _settingRow(
                          context,
                          Icons.show_chart,
                          'Progress Tracker',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProgressScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        _settingRow(
                          context,
                          Icons.bedtime_outlined,
                          'Daily Recovery Check-in',
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RecoveryScreen(),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                        _settingRow(
                          context,
                          Icons.notifications_outlined,
                          'Notifications',
                          () {},
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Logout
                  AppButton(
                    label: 'Sign Out',
                    onPressed: _logout,
                    outlined: true,
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _statItem(
    BuildContext context,
    String label,
    String value,
    String unit,
  ) {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _divider() {
    return Container(height: 40, width: 1, color: AppColors.border);
  }

  Widget _settingRow(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textMuted,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
