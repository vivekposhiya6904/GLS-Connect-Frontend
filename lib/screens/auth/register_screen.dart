import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

// ───────────────── COLORS ─────────────────

const Color glsBlue = Color(0xFF1A3A8F);
const Color glsBlueMid = Color(0xFF5B7FCC);
const Color glsBlueSoft = Color(0xFF7A9DD4);
const Color glsFieldBg = Color(0xFFF4F7FF);
const Color glsFieldBorder = Color(0xFFD8E3F8);
const Color glsTextDark = Color(0xFF0D1B40);
const Color glsTextMuted = Color(0xFF8899BB);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final universityNoController = TextEditingController();



  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> registerUser() async {

    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        universityNoController.text.isEmpty) {

      showMessage("Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    try {

      final response = await AuthService.registerUser(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        universityNo: universityNoController.text.trim(),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful"),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
        );

      } else {

        showMessage("Registration failed");
      }

    } catch (e) {

      showMessage("Network error");
    }

    setState(() => isLoading = false);
  }

  void showMessage(String msg) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: glsBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
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

      body: SafeArea(
        child: SingleChildScrollView(

          physics: const ClampingScrollPhysics(),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 80),

              // ───────── BRAND HEADER ─────────

              _buildBrandHeader(),

              // const SizedBox(height: 40),

              // ───────── ILLUSTRATION ─────────

              // const _RegisterIllustration(),

              const SizedBox(height: 40),

              // ───────── FORM ─────────

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  6,
                  24,
                  0,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: glsTextDark,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      "Join the alumni network & stay connected",
                      style: TextStyle(
                        fontSize: 13,
                        color: glsTextMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ───── FULL NAME ─────

                    _fieldLabel("Full Name"),

                    const SizedBox(height: 8),

                    TextField(
                      controller: nameController,

                      style: const TextStyle(
                        fontSize: 14,
                        color: glsTextDark,
                      ),

                      decoration: _inputDecoration(
                        hint: "Enter your full name",

                        prefix: const Icon(
                          Icons.person_outline_rounded,
                          color: glsBlueSoft,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ───── UNIVERSITY NUMBER ─────

                    _fieldLabel("University Number"),

                    const SizedBox(height: 8),

                    TextField(
                      controller: universityNoController,
                      keyboardType: TextInputType.number,

                      style: const TextStyle(
                        fontSize: 14,
                        color: glsTextDark,
                      ),

                      decoration: _inputDecoration(
                        hint: "Enter university number",

                        prefix: const Icon(
                          Icons.badge_outlined,
                          color: glsBlueSoft,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ───── EMAIL ─────

                    _fieldLabel("Email Address"),

                    const SizedBox(height: 8),

                    TextField(
                      controller: emailController,

                      style: const TextStyle(
                        fontSize: 14,
                        color: glsTextDark,
                      ),

                      decoration: _inputDecoration(
                        hint: "you@gls.edu.in",

                        prefix: const Icon(
                          Icons.mail_outline_rounded,
                          color: glsBlueSoft,
                          size: 20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ───── PASSWORD ─────

                    _fieldLabel("Password"),

                    const SizedBox(height: 8),

                    TextField(
                      controller: passwordController,
                      obscureText: obscurePassword,

                      style: const TextStyle(
                        fontSize: 14,
                        color: glsTextDark,
                      ),

                      decoration: _inputDecoration(

                        hint: "Create password",

                        prefix: const Icon(
                          Icons.lock_outline_rounded,
                          color: glsBlueSoft,
                          size: 20,
                        ),

                        suffix: IconButton(

                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,

                            color: glsBlueSoft,
                            size: 20,
                          ),

                          onPressed: () {

                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),


                    const SizedBox(height: 28),

                    // ───── BUTTON ─────

                    SizedBox(
                      width: double.infinity,
                      height: 54,

                      child: ElevatedButton(

                        onPressed: isLoading
                            ? null
                            : registerUser,

                        style: ElevatedButton.styleFrom(
                          backgroundColor: glsBlue,
                          disabledBackgroundColor:
                          glsBlue.withOpacity(0.55),

                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),

                        child: isLoading

                            ? const SizedBox(
                          width: 22,
                          height: 22,

                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )

                            : Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,

                          children: [

                            const Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),

                            const SizedBox(width: 10),

                            Container(
                              width: 28,
                              height: 28,

                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),

                                borderRadius:
                                BorderRadius.circular(8),
                              ),

                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ───── LOGIN TEXT ─────

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        Text(
                          "Already have an account?",
                          style: TextStyle(
                            fontSize: 11,
                            color:
                            glsTextMuted.withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(width: 6),

                        GestureDetector(

                          onTap: () {

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const LoginScreen(),
                              ),
                            );
                          },

                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: glsBlue,
                              decoration:
                              TextDecoration.underline,

                              decorationColor: glsBlue,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────── BRAND HEADER ─────────

  Widget _buildBrandHeader() {

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        24,
        20,
        24,
        0,
      ),

      child: Row(
        children: [

          Container(
            width: 40,
            height: 40,

            decoration: BoxDecoration(
              color: glsBlue,
              borderRadius: BorderRadius.circular(10),
            ),

            child: const Icon(
              Icons.hub_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                "GLS Connect",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: glsBlue,
                  letterSpacing: 0.2,
                ),
              ),

              SizedBox(height: 2),

              Text(
                "CONNECT · GROW · BELONG",
                style: TextStyle(
                  fontSize: 8.5,
                  color: glsBlueMid,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────── FIELD LABEL ─────────

  Widget _fieldLabel(String label) {

    return Text(
      label.toUpperCase(),

      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: glsBlue,
        letterSpacing: 0.9,
      ),
    );
  }

  // ───────── INPUT DECORATION ─────────

  InputDecoration _inputDecoration({
    required String hint,
    required Widget prefix,
    Widget? suffix,
  }) {

    return InputDecoration(

      hintText: hint,

      hintStyle: const TextStyle(
        color: Color(0xFFB8C8E8),
        fontSize: 13,
      ),

      filled: true,
      fillColor: glsFieldBg,

      prefixIcon: prefix,
      suffixIcon: suffix,

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),

        borderSide: const BorderSide(
          color: glsFieldBorder,
          width: 1.5,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),

        borderSide: const BorderSide(
          color: glsBlue,
          width: 1.8,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
// REGISTER ILLUSTRATION
// ═════════════════════════════════════════════════════════════════════

class _RegisterIllustration extends StatelessWidget {
  const _RegisterIllustration();

  @override
  Widget build(BuildContext context) {

    return SizedBox(
      width: double.infinity,
      height: 172,

      child: CustomPaint(
        painter: _IllustrationPainter(),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {

  @override
  void paint(Canvas canvas, Size size) {

    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.58),
        width: 170,
        height: 90,
      ),

      Paint()
        ..color = const Color(0xFFF0F5FF),
    );

    final center = Offset(w * 0.50, h * 0.38);

    canvas.drawCircle(
      center,
      26,

      Paint()
        ..color = glsBlue,
    );

    _drawIcon(
      canvas,
      center,
      Icons.person_add_alt_1_rounded,
      Colors.white,
      28,
    );

    final left = Offset(w * 0.28, h * 0.65);
    final right = Offset(w * 0.72, h * 0.65);

    _miniNode(canvas, left, "Student");
    _miniNode(canvas, right, "Faculty");

    _dashed(canvas, center, left);
    _dashed(canvas, center, right);
  }

  void _miniNode(
      Canvas canvas,
      Offset c,
      String text,
      ) {

    canvas.drawCircle(
      c,
      18,

      Paint()
        ..color = Colors.white,
    );

    canvas.drawCircle(
      c,
      18,

      Paint()
        ..color = const Color(0xFFC5D6F5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    _drawIcon(
      canvas,
      c,
      Icons.person_outline_rounded,
      glsBlue,
      18,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: text,

        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: glsBlue,
        ),
      ),

      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        c.dx - tp.width / 2,
        c.dy + 24,
      ),
    );
  }

  void _drawIcon(
      Canvas canvas,
      Offset c,
      IconData icon,
      Color color,
      double size,
      ) {

    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),

        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),

      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(
        c.dx - tp.width / 2,
        c.dy - tp.height / 2,
      ),
    );
  }

  void _dashed(Canvas canvas, Offset a, Offset b) {

    final paint = Paint()
      ..color = const Color(0xFFC5D6F5)
      ..strokeWidth = 1.5;

    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;

    final len = Offset(dx, dy).distance;

    const dash = 4.0;
    const gap = 3.0;

    double d = 0;

    while (d < len) {

      final t0 = d / len;
      final t1 = ((d + dash) / len).clamp(0.0, 1.0);

      canvas.drawLine(
        Offset(
          a.dx + dx * t0,
          a.dy + dy * t0,
        ),

        Offset(
          a.dx + dx * t1,
          a.dy + dy * t1,
        ),

        paint,
      );

      d += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}