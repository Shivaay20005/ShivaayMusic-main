import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shivaaymusic/services/auth_service.dart';
import 'package:shivaaymusic/ui/widgets/snackbar.dart';

import '../Home/home_screen_controller.dart';
import '../../home.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = Get.find<AuthService>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      final result = await _authService.signUpWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (result['success']) {
        showCustomSnackbar(
          title: "Success",
          message: result['message'],
        );
        // Navigation to home is handled by auth state change in main.dart
        if (Get.isRegistered<HomeScreenController>()) {
           Get.find<HomeScreenController>().tabIndex.value = 0;
        }
        if (mounted) {
          Get.offAll(() => const Home());
        }
      } else {
        showCustomSnackbar(
          title: "Sign Up Failed",
          message: result['message'],
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget buildTextField({
      required TextEditingController controller,
      required String label,
      required IconData icon,
      bool isPassword = false,
      bool? obscureText,
      VoidCallback? onToggleObscure,
      TextInputAction textInputAction = TextInputAction.next,
      ValueChanged<String>? onSubmitted,
      TextCapitalization textCapitalization = TextCapitalization.none,
      String? Function(String?)? validator,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          ),
        ),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText ?? false,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          textCapitalization: textCapitalization,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: isDark ? Colors.white70 : theme.colorScheme.primary),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      (obscureText ?? false) ? Icons.visibility_off : Icons.visibility,
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                    onPressed: onToggleObscure,
                  )
                : null,
            labelText: label,
            labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
             floatingLabelStyle: TextStyle(
                color: isDark ? Colors.white : theme.colorScheme.primary,
                fontWeight: FontWeight.bold),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
          validator: validator,
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.9),
                  isDark ? Colors.black : theme.colorScheme.surface,
                ],
              ),
            ),
          ),
          
          // 2. Background Elements
          Positioned(
            top: -30,
            left: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withValues(alpha: 0.3),
              ),
            ),
          ),
           Positioned(
            bottom: -50,
            right: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
              ),
            ),
          ),

          // 3. Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                       // Back Button (Floating style)
                       Align(
                         alignment: Alignment.topLeft,
                         child: IconButton(
                           icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
                           onPressed: () => Get.back(),
                           style: IconButton.styleFrom(
                             backgroundColor: isDark ? Colors.white10 : Colors.white,
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                           ),
                         ),
                       ),
                      const SizedBox(height: 20),
                      
                      // Title
                      Text(
                        'Create Account',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Join ShivaayMusic today!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Fields
                      buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_rounded,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your name';
                            if (value.length < 2) return 'Name must be at least 2 characters';
                            return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.alternate_email_rounded,
                        validator: (value) {
                             if (value == null || value.isEmpty) return 'Please enter your email';
                             if (!GetUtils.isEmail(value)) return 'Please enter a valid email';
                             return null;
                        }
                      ),
                      const SizedBox(height: 16),
                      
                      buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                        validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your password';
                            if (value.length < 6) return 'Min 6 characters';
                            return null;
                        }
                      ),
                      const SizedBox(height: 16),
                      
                      buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        icon: Icons.lock_reset_rounded,
                        isPassword: true,
                         obscureText: _obscureConfirmPassword,
                        onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleSignUp(),
                        validator: (value) {
                            if (value == null || value.isEmpty) return 'Please confirm your password';
                            if (value != _passwordController.text) return 'Passwords do not match';
                            return null;
                        }
                      ),
                      
                      const SizedBox(height: 40),

                      // Sign Up Button
                      Obx(() => SizedBox(
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _authService.isLoading.value ? null : _handleSignUp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : theme.colorScheme.primary,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                elevation: 8,
                                shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _authService.isLoading.value
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    )
                                  : const Text(
                                      'SIGN UP',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          )),
                      
                      const SizedBox(height: 30),
                      
                       // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          ),
                          GestureDetector(
                            onTap: () => Get.back(),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                color: isDark ? Colors.white : theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
