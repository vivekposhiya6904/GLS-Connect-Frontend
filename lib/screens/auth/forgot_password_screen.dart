import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

const Color glsBlue        = Color(0xFF1A3A8F);
const Color glsBlueMid     = Color(0xFF5B7FCC);
const Color glsBlueSoft    = Color(0xFF7A9DD4);
const Color glsFieldBg     = Color(0xFFF4F7FF);
const Color glsFieldBorder = Color(0xFFD8E3F8);
const Color glsTextDark    = Color(0xFF0D1B40);
const Color glsTextMuted   = Color(0xFF8899BB);

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _obscurePassword = true;
  String? _generatedOtp;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _requestOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage("Please enter your registered email");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.forgotPassword(email);
      setState(() {
        _otpSent = true;
        _generatedOtp = response['otp'];
      });
      _showMessage("OTP generated successfully!", isError: false);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    if (otp.isEmpty || newPassword.isEmpty) {
      _showMessage("Please enter the OTP and your new password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await AuthService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );

      if (success) {
        _showMessage("Password reset successfully! Please log in.", isError: false);
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration({required String hint, required Widget prefix, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: glsTextMuted, fontSize: 14),
      prefixIcon: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: glsFieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: glsFieldBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: glsBlue, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: glsTextDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Reset Password",
          style: TextStyle(color: glsTextDark, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_reset_rounded,
                size: 64,
                color: glsBlue,
              ),
              const SizedBox(height: 16),
              Text(
                _otpSent ? "Enter OTP & New Password" : "Forgot Your Password?",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: glsTextDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _otpSent
                    ? "We have generated an OTP for ${_emailController.text}. Enter it below along with your new password."
                    : "Enter your registered email address to receive a password reset OTP.",
                style: const TextStyle(fontSize: 14, color: glsTextMuted, height: 1.4),
              ),
              const SizedBox(height: 32),

              if (!_otpSent) ...[
                const Text(
                  "Email Address",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: glsTextDark),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14, color: glsTextDark),
                  decoration: _inputDecoration(
                    hint: "you@gls.edu.in",
                    prefix: const Icon(Icons.mail_outline_rounded, color: glsBlueSoft),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: glsBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Send OTP",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
              ] else ...[
                if (_generatedOtp != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: glsBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: glsBlue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: glsBlue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Your Demo OTP is: $_generatedOtp",
                            style: const TextStyle(
                              color: glsBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                const Text(
                  "6-Digit OTP",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: glsTextDark),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 4, color: glsTextDark),
                  decoration: _inputDecoration(
                    hint: "123456",
                    prefix: const Icon(Icons.pin_outlined, color: glsBlueSoft),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "New Password",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: glsTextDark),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontSize: 14, color: glsTextDark),
                  decoration: _inputDecoration(
                    hint: "Enter new password",
                    prefix: const Icon(Icons.lock_outline_rounded, color: glsBlueSoft),
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: glsBlueSoft,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: glsBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Reset Password",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _otpSent = false),
                    child: const Text(
                      "Resend OTP or Change Email",
                      style: TextStyle(color: glsBlue, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
