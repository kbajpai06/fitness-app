import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme.dart';
import '../../core/api_client.dart';
import '../../widgets/app_button.dart';
import 'register_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading       = false;
  bool _obscure       = true;

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      // Login uses form data
      final res = await _doLogin(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
      );
      await ApiClient.saveToken(res['access_token']);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Login needs form encoding not JSON
  Future<Map<String, dynamic>> _doLogin(String email, String password) async {
  final res = await ApiClient.postForm('/auth/login', {
    'username': email,
    'password': password,
  });
  return res;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),

              // Logo / Brand
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.bolt, color: AppColors.background, size: 24),
              ),
              const SizedBox(height: 32),

              Text('Welcome back.', style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Your fitness journey continues.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 48),

              // Email
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@example.com',
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 32),

              AppButton(
                label: 'Continue',
                onPressed: _login,
                isLoading: _loading,
              ),
              const SizedBox(height: 24),

              // Register link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account? ",
                    style: Theme.of(context).textTheme.bodyMedium),
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Sign up',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      )),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}