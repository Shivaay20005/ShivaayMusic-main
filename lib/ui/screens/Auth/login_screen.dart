import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:shivaaymusic/services/auth_service.dart';
import 'package:shivaaymusic/ui/screens/Auth/signup_screen.dart';
import 'package:shivaaymusic/ui/widgets/snackbar.dart';

import '../Home/home_screen_controller.dart';
import '../../home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = Get.find<AuthService>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final result = await _authService.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success']) {
        // Navigation to home will be handled automatically by auth state change
        showCustomSnackbar(
          title: "Success",
          message: result['message'],
        );
        // Ensure we start at Home tab (index 0)
        if (Get.isRegistered<HomeScreenController>()) {
           Get.find<HomeScreenController>().tabIndex.value = 0;
        }
        if (mounted) {
          Get.offAll(() => const Home());
        }
      } else {
        showCustomSnackbar(
          title: "Login Failed",
          message: result['message'],
          isError: true,
        );
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    if (_emailController.text.isEmpty) {
      showCustomSnackbar(
        title: "Error",
        message: "Please enter your email address first",
        isError: true,
      );
      return;
    }

    final result = await _authService.resetPassword(
      email: _emailController.text.trim(),
    );

    showCustomSnackbar(
      title: result['success'] ? "Success" : "Error",
      message: result['message'],
      isError: !result['success'],
    );
  }

  Future<void> _handleGoogleSignIn() async {
    final result = await _authService.signInWithGoogle();

    if (result['success']) {
      showCustomSnackbar(
        title: "Success",
        message: result['message'],
      );
      // Ensure we start at Home tab (index 0)
      if (Get.isRegistered<HomeScreenController>()) {
        Get.find<HomeScreenController>().tabIndex.value = 0;
      }
      if (mounted) {
        Get.offAll(() => const Home());
      }
    } else {
      showCustomSnackbar(
        title: "Login Failed",
        message: result['message'],
        isError: true,
      );
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
      TextInputAction textInputAction = TextInputAction.next,
      ValueChanged<String>? onSubmitted,
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
          obscureText: isPassword ? _obscurePassword : false,
          textInputAction: textInputAction,
          onFieldSubmitted: onSubmitted,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: isDark ? Colors.white70 : theme.colorScheme.primary),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: isDark ? Colors.white60 : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
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
          validator: (value) {
            if (value == null || value.isEmpty) return 'This field is required';
            if (!isPassword && !GetUtils.isEmail(value)) return 'Please enter a valid email';
            if (isPassword && value.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
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
          
          // 2. Artistic Background Elements (Circles)
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withValues(alpha: 0.3),
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
                      const SizedBox(height: 20),
                      // Logo
                      Center(
                        child: Hero(
                          tag: 'app_logo',
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2), 
                                width: 2
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.transparent,
                              backgroundImage: AssetImage('assets/icons/imagelogo.png'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),

                      // Welcome Text
                      Text(
                        'Welcome Back!',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 1.0,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Login to continue your musical journey',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // Input Fields
                      buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.alternate_email_rounded,
                      ),
                      const SizedBox(height: 20),
                      buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(),
                      ),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : theme.colorScheme.primary,
                          ),
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Button
                      Obx(() => SizedBox(
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _authService.isLoading.value ? null : _handleLogin,
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
                                      'LOGIN',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          )),
                      
                      const SizedBox(height: 20),
                      
                      if (!Platform.isWindows) ...[
                      // OR Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "OR",
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Google Sign-In Button
                      Obx(() => SizedBox(
                            height: 55,
                            child: OutlinedButton.icon(
                              onPressed: _authService.isLoading.value ? null : _handleGoogleSignIn,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark ? Colors.white30 : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                foregroundColor: isDark ? Colors.white : Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: _authService.isLoading.value
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2.5),
                                    )
                                  : Image.asset(
                                      'assets/images/google_logo.png',
                                      height: 24,
                                      width: 24,
                                      errorBuilder: (context, error, stackTrace) {
                                        // Fallback to text if image not found
                                        return const Icon(Icons.g_mobiledata, size: 28);
                                      },
                                    ),
                              label: Text(
                                'Continue with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          )),
                      ],
                      
                      const SizedBox(height: 40),
                      
                      // Bottom Section
                      Row(
                        children: [
                          Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Don't have an account?",
                              style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600),
                            ),
                          ),
                           Expanded(child: Divider(color: isDark ? Colors.white24 : Colors.grey.shade300)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Get.to(() => const SignUpScreen()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : theme.colorScheme.primary,
                            side: BorderSide(
                              color: isDark ? Colors.white30 : theme.colorScheme.primary.withValues(alpha: 0.3),
                              width: 1.5
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Create Account',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
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
