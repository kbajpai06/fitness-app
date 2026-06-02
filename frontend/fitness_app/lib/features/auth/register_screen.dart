import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/app_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading       = false;
  bool _obscure       = true;

  Future<void> _register() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await ApiClient.post('/auth/register', {
        'full_name': _nameCtrl.text.trim(),
        'email':     _emailCtrl.text.trim(),
        'password':  _passwordCtrl.text,
      }, auth: false);
      await ApiClient.saveToken(res['access_token']);
      if (mounted) Navigator.pushReplacementNamed(context, '/onboarding');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              Text('Create account.', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text('Start your transformation today.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary)),
              const SizedBox(height: 48),

              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Full Name', hintText: 'Arjun Sharma'),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Min. 8 characters',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textMuted),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              AppButton(label: 'Create Account', onPressed: _register, isLoading: _loading),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}