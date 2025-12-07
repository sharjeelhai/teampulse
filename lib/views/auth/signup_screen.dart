import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../models/user_model.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dropdown.dart';
import '../../widgets/loading_overlay.dart';
import '../splash/splash_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.member;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    final success = await authViewModel.signUp(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authViewModel.errorMessage ?? 'Signup failed'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          return LoadingOverlay(
            isLoading: authViewModel.isLoading,
            message: 'Creating account...',
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Join TeamPulse today',
                        style: TextStyle(fontSize: 16, color: Colors.white60),
                      ),
                      const SizedBox(height: 32),
                      AppInput(
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        controller: _nameController,
                        prefixIcon: Icons.person_outline,
                        validator: Validators.validateName,
                        readOnly: false,
                      ),
                      const SizedBox(height: 20),
                      AppInput(
                        label: 'Email',
                        hint: 'Enter your email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                        validator: Validators.validateEmail,
                        readOnly: false,
                      ),
                      const SizedBox(height: 20),
                      AppInput(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        onSuffixIconTap: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        validator: Validators.validatePassword,
                        readOnly: false,
                      ),
                      const SizedBox(height: 20),
                      AppDropdown<UserRole>(
                        label: 'Role',
                        value: _selectedRole,
                        items: UserRole.values.map((role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(
                              role
                                  .toString()
                                  .split('.')
                                  .last
                                  .replaceAllMapped(
                                    RegExp(r'([A-Z])'),
                                    (match) => ' ${match.group(0)}',
                                  )
                                  .trim(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRole = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      AppButton(
                        text: 'Sign Up',
                        onPressed: _handleSignup,
                        icon: Icons.person_add,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
