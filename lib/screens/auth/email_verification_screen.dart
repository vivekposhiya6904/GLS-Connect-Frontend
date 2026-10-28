import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

// ───────────────── GLS COLORS ─────────────────
const Color glsBlue = Color(0xFF1A3A8F);
const Color glsBlueMid = Color(0xFF5B7FCC);
const Color glsBlueSoft = Color(0xFF7A9DD4);
const Color glsFieldBg = Color(0xFFF4F7FF);
const Color glsFieldBorder = Color(0xFFD8E3F8);
const Color glsTextDark = Color(0xFF0D1B40);
const Color glsTextMuted = Color(0xFF8899BB);

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String purpose;
  final int initialCooldownSeconds;
  final bool otpDispatched;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.purpose = "ACCOUNT_REGISTRATION",
    this.initialCooldownSeconds = 60,
    this.otpDispatched = true,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  bool _isVerifying = false;
  bool _isResending = false;
  int _cooldownSeconds = 60;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer(widget.initialCooldownSeconds);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = seconds);

    if (seconds <= 0) return;

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownSeconds = 0);
      } else {
        if (mounted) setState(() => _cooldownSeconds--);
      }
    });
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? const Color(0xFFD32F2F) : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;

    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showMessage("Please enter the complete 6-digit code");
      return;
    }

    setState(() => _isVerifying = true);

    try {
      await AuthService.verifyOtp(
        email: widget.email,
        otp: otp,
        purpose: widget.purpose,
      );

      if (!mounted) return;

      _showMessage("Email verified successfully! Please log in.", isError: false);

      // Navigate to LoginScreen and clear backstack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_cooldownSeconds > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      final res = await AuthService.resendOtp(
        email: widget.email,
        purpose: widget.purpose,
      );

      if (!mounted) return;

      _showMessage("A fresh 6-digit code has been sent to your inbox", isError: false);
      int cooldown = 60;
      if (res['cooldownSeconds'] != null) {
        cooldown = int.tryParse(res['cooldownSeconds'].toString()) ?? 60;
      }
      _startCooldownTimer(cooldown);
    } catch (e) {
      _showMessage(e.toString());
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: glsTextDark, size: 20),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
        ),
        title: const Text(
          "Verify Email",
          style: TextStyle(color: glsTextDark, fontWeight: FontWeight.w800, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // ── Header Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: glsBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 42,
                  color: glsBlue,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                "Check Your Inbox",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: glsTextDark,
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "We have sent a 6-digit verification code to:\n${widget.email}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: glsTextMuted,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              if (!widget.otpDispatched) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.amber.shade900, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "If you already received a code recently, please enter it below. Otherwise, tap Resend Code when the timer completes.",
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── OTP Input
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "ENTER 6-DIGIT CODE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: glsBlue,
                    letterSpacing: 0.9,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 10,
                  color: glsTextDark,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "••••••",
                  hintStyle: const TextStyle(
                    color: Color(0xFFB8C8E8),
                    fontSize: 22,
                    letterSpacing: 10,
                  ),
                  filled: true,
                  fillColor: glsFieldBg,
                  contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: glsFieldBorder, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: glsBlue, width: 1.8),
                  ),
                ),
                onSubmitted: (_) => _verifyOtp(),
              ),

              const SizedBox(height: 10),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: glsTextMuted),
                  SizedBox(width: 4),
                  Text(
                    "Code expires in 5 minutes",
                    style: TextStyle(fontSize: 12, color: glsTextMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Verify Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: glsBlue,
                    disabledBackgroundColor: glsBlue.withValues(alpha: 0.55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          "Verify Code",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Resend Code Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the email?",
                    style: TextStyle(
                      fontSize: 12,
                      color: glsTextMuted.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: (_cooldownSeconds == 0 && !_isResending) ? _resendOtp : null,
                    child: Text(
                      _cooldownSeconds > 0
                          ? "Resend in ${_cooldownSeconds}s"
                          : (_isResending ? "Sending..." : "Resend Code"),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _cooldownSeconds > 0 ? glsTextMuted : glsBlue,
                        decoration: _cooldownSeconds == 0 ? TextDecoration.underline : TextDecoration.none,
                        decorationColor: glsBlue,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ── Return to Login
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text(
                  "Return to Login",
                  style: TextStyle(color: glsTextMuted, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
