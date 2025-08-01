// lib/screens/auth/verify_email_screen.dart - FIXED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../core/utils/validators.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;

  const VerifyEmailScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isVerifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Prevent multiple submissions
    if (_isVerifying) return;
    
    setState(() {
      _isVerifying = true;
    });

    try {
      // Clear any previous errors
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.clearError();

      print('🔐 Starting email verification...');
      print('Email: ${widget.email}');
      print('Code: ${_codeController.text}');

      final success = await authProvider.verifyEmail(
        widget.email,
        _codeController.text,
      );

      if (mounted) {
        if (success) {
          print('✅ Verification successful!');
          
          // Use Navigator.pushAndRemoveUntil to prevent state issues
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
            (route) => false, // Remove all previous routes
          );
        } else {
          print('❌ Verification failed');
          // Error will be shown by Consumer<AuthProvider> below
        }
      }
    } catch (e) {
      print('❌ Verification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Verify Your Email',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  'We sent a verification code to\n${widget.email}\n\nFor demo: use code 123456',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Verification Code Input
                CustomTextField(
                  label: 'Verification Code',
                  hint: 'Enter 6-digit code (demo: 123456)',
                  controller: _codeController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter verification code';
                    }
                    if (value.length != 6) {
                      return 'Code must be 6 digits';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  prefixIcon: const Icon(Icons.security),
                ),
                
                const SizedBox(height: 32),
                
                // Error Display
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.error != null) {
                      // Use post frame callback to avoid setState during build
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(authProvider.error!),
                              backgroundColor: AppColors.error,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          authProvider.clearError();
                        }
                      });
                    }
                    
                    return const SizedBox.shrink(); // Empty widget
                  },
                ),
                
                // Verify Button
                CustomButton(
                  text: 'Verify Email',
                  onPressed: _isVerifying ? null : _verifyEmail,
                  isLoading: _isVerifying,
                  backgroundColor: AppColors.primary,
                ),
                
                const SizedBox(height: 24),
                
                // Resend Code Button
                TextButton(
                  onPressed: _isVerifying ? null : () {
                    // For demo, just show the code again
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Demo Code: 123456'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: const Text(
                    'Resend Code (Demo: 123456)',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
                
                const Spacer(),
                
                // Demo Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demo Mode: Always use code 123456',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}