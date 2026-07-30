import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import '../router/dashboard_router.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

// ─── GLS Brand Palette ───────────────────────────────────────────────
const Color glsBlue        = Color(0xFF1A3A8F);
const Color glsBlueMid     = Color(0xFF5B7FCC);
const Color glsBlueSoft    = Color(0xFF7A9DD4);
const Color glsFieldBg     = Color(0xFFF4F7FF);
const Color glsFieldBorder = Color(0xFFD8E3F8);
const Color glsTextDark    = Color(0xFF0D1B40);
const Color glsTextMuted   = Color(0xFF8899BB);
const Color glsDivider     = Color(0xFFE8EEF8);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading       = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await AuthService.loginUser(
        email:    email,
        password: password,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardRouter()),
        );
      } else {
        _showMessage("Invalid email or password");
      }
    } catch (e) {
      _showMessage("Network error. Please try again.");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: glsBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor:          Colors.white,
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

              const SizedBox(height: 40,),
              // ── Brand header
              _buildBrandHeader(),

              const SizedBox(height: 40,),

              // ── Network illustration
              const _ConnectIllustration(),

              const SizedBox(height: 40,),

              // ── Form section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    const Text(
                      "Welcome Back ",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: glsTextDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "Sign in — we'll take you to the right place",
                      style: TextStyle(
                        fontSize: 13,
                        color: glsTextMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 26),

                    // Email
                    _fieldLabel("Email Address"),
                    const SizedBox(height: 8),
                    _emailField(),

                    const SizedBox(height: 16),

                    // Password
                    _fieldLabel("Password"),
                    const SizedBox(height: 8),
                    _passwordField(),

                    const SizedBox(height: 10),

                    // Forgot password
                    _forgotPassword(),

                    const SizedBox(height: 22),

                    // Sign In button
                    _signInButton(),

                    const SizedBox(height: 22),

                    // Divider + Register
                    _orDivider(),

                    const SizedBox(height: 16),

                    _registerRow(),

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

  // ─────────────────────────────────────────────────────────────────
  //  Brand header
  // ─────────────────────────────────────────────────────────────────
  Widget _buildBrandHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
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

  // ─────────────────────────────────────────────────────────────────
  //  Field label
  // ─────────────────────────────────────────────────────────────────
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

  // ─────────────────────────────────────────────────────────────────
  //  Input decoration helper
  // ─────────────────────────────────────────────────────────────────
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
        borderSide: const BorderSide(color: glsFieldBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: glsBlue, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE24B4A), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE24B4A), width: 1.8),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Email field
  // ─────────────────────────────────────────────────────────────────
  Widget _emailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: const TextStyle(fontSize: 14, color: glsTextDark),
      decoration: _inputDecoration(
        hint: "you@gls.edu.in",
        prefix: const Icon(
          Icons.mail_outline_rounded,
          color: glsBlueSoft,
          size: 20,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Password field
  // ─────────────────────────────────────────────────────────────────
  Widget _passwordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _loginUser(),
      style: const TextStyle(fontSize: 14, color: glsTextDark),
      decoration: _inputDecoration(
        hint: "Enter your password",
        prefix: const Icon(
          Icons.lock_outline_rounded,
          color: glsBlueSoft,
          size: 20,
        ),
        suffix: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: glsBlueSoft,
            size: 20,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Forgot password
  // ─────────────────────────────────────────────────────────────────
  Widget _forgotPassword() {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
          );
        },
        child: const Text(
          "Forgot password?",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: glsBlue,
            decoration: TextDecoration.underline,
            decorationColor: glsBlue,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Sign In button
  // ─────────────────────────────────────────────────────────────────
  Widget _signInButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _loginUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: glsBlue,
          disabledBackgroundColor: glsBlue.withOpacity(0.55),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.5,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Sign In",
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
                borderRadius: BorderRadius.circular(8),
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
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Divider
  // ─────────────────────────────────────────────────────────────────
  Widget _orDivider() {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: glsDivider, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            "Don't have an account?",
            style: TextStyle(
              fontSize: 11,
              color: glsTextMuted.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: glsDivider, thickness: 1),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  //  Register row
  // ─────────────────────────────────────────────────────────────────
  Widget _registerRow() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
        ),
        child: const Text(
          "Create an account",
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: glsBlue,
            decoration: TextDecoration.underline,
            decorationColor: glsBlue,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════
//  Connect Illustration  —  pure CustomPainter, zero image assets
// ═════════════════════════════════════════════════════════════════════

class _ConnectIllustration extends StatelessWidget {
  const _ConnectIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 172,
      child: CustomPaint(painter: _IllustrationPainter()),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── Soft background blobs ─────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.16, h * 0.78), width: 106, height: 64),
      Paint()..color = const Color(0xFFEEF3FF),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.84, h * 0.76), width: 96, height: 60),
      Paint()..color = const Color(0xFFEEF3FF),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.56), width: 148, height: 86),
      Paint()..color = const Color(0xFFF0F5FF),
    );

    // ── Node centres ─────────────────────────────────────────────
    final hub    = Offset(w * 0.50, h * 0.28);
    final nodeL  = Offset(w * 0.26, h * 0.48);
    final nodeR  = Offset(w * 0.74, h * 0.48);
    final nodeBL = Offset(w * 0.13, h * 0.76);
    final nodeBR = Offset(w * 0.87, h * 0.74);

    // ── Dashed connector lines ────────────────────────────────────
    _dashed(canvas, hub, nodeL,  const Color(0xFFC5D6F5), 1.5);
    _dashed(canvas, hub, nodeR,  const Color(0xFFC5D6F5), 1.5);
    _dashed(canvas, hub, nodeBL, const Color(0xFFD8E6FA), 1.0);
    _dashed(canvas, hub, nodeBR, const Color(0xFFD8E6FA), 1.0);
    _dashed(canvas, nodeL,  nodeBL, const Color(0xFFD8E6FA), 1.0);
    _dashed(canvas, nodeR,  nodeBR, const Color(0xFFD8E6FA), 1.0);

    // ── Central hub ───────────────────────────────────────────────
    canvas.drawCircle(hub, 24, Paint()..color = const Color(0xFF1A3A8F));
    _drawText(canvas, "GL", hub, 14, Colors.white, FontWeight.w900);

    // ── Person nodes ──────────────────────────────────────────────
    _personNode(canvas, nodeL,  21, const Color(0xFF5B7FCC), "Alumni");
    _personNode(canvas, nodeR,  21, const Color(0xFF1A3A8F), "Faculty");
    _personNode(canvas, nodeBL, 17, const Color(0xFF7A9DD4), "Student");
    _personNode(canvas, nodeBR, 17, const Color(0xFF7A9DD4), "Student");

    // ── Floating micro icon bubbles ───────────────────────────────
    _iconBubble(canvas, Offset(w * 0.36, h * 0.06), 17,
        Icons.chat_bubble_outline_rounded, const Color(0xFF5B7FCC));
    _iconBubble(canvas, Offset(w * 0.64, h * 0.05), 17,
        Icons.star_border_rounded,         const Color(0xFFF59E0B));
    _iconBubble(canvas, Offset(w * 0.06, h * 0.44), 14,
        Icons.phone_outlined,              const Color(0xFF5B7FCC));
    _iconBubble(canvas, Offset(w * 0.94, h * 0.42), 14,
        Icons.work_outline_rounded,        const Color(0xFF1A3A8F));
    _iconBubble(canvas, Offset(w * 0.43, h * 0.90), 14,
        Icons.menu_book_rounded,           const Color(0xFF1A3A8F));
    _iconBubble(canvas, Offset(w * 0.57, h * 0.92), 14,
        Icons.lightbulb_outline_rounded,   const Color(0xFFF59E0B));
    _iconBubble(canvas, Offset(w * 0.91, h * 0.22), 13,
        Icons.wifi_rounded,                const Color(0xFF5B7FCC));
    _iconBubble(canvas, Offset(w * 0.09, h * 0.22), 13,
        Icons.notifications_outlined,      const Color(0xFF1A3A8F));
  }

  // ── Person node ──────────────────────────────────────────────────
  void _personNode(Canvas canvas, Offset c, double r,
      Color color, String label) {
    // circle background
    canvas.drawCircle(c, r, Paint()..color = Colors.white);
    canvas.drawCircle(
        c, r,
        Paint()
          ..color = const Color(0xFFC5D6F5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    // head
    canvas.drawCircle(
        Offset(c.dx, c.dy - r * 0.28),
        r * 0.30,
        Paint()..color = color);
    // shoulders
    final path = Path()
      ..moveTo(c.dx - r * 0.65, c.dy + r * 0.55)
      ..quadraticBezierTo(
          c.dx, c.dy + r * 0.20,
          c.dx + r * 0.65, c.dy + r * 0.55);
    canvas.drawPath(path, Paint()..color = color);
    // label
    _drawText(canvas, label,
        Offset(c.dx, c.dy + r + 11), 8.5, color, FontWeight.w700);
  }

  // ── Icon bubble ───────────────────────────────────────────────────
  void _iconBubble(Canvas canvas, Offset c, double size,
      IconData icon, Color color) {
    final side = size * 1.55;
    final rr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: side, height: side),
        const Radius.circular(5));
    canvas.drawRRect(rr, Paint()..color = const Color(0xFFEEF3FF));
    canvas.drawRRect(
        rr,
        Paint()
          ..color = const Color(0xFFC5D6F5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0);
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size * 0.68,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
  }

  // ── Dashed line ───────────────────────────────────────────────────
  void _dashed(Canvas canvas, Offset a, Offset b, Color color, double w) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = w;
    final dx  = b.dx - a.dx;
    final dy  = b.dy - a.dy;
    final len = Offset(dx, dy).distance;
    const dash = 4.0, gap = 3.5;
    double d = 0;
    while (d < len) {
      final t0 = d / len;
      final t1 = ((d + dash) / len).clamp(0.0, 1.0);
      canvas.drawLine(
          Offset(a.dx + dx * t0, a.dy + dy * t0),
          Offset(a.dx + dx * t1, a.dy + dy * t1),
          paint);
      d += dash + gap;
    }
  }

  // ── Text helper ───────────────────────────────────────────────────
  void _drawText(Canvas canvas, String s, Offset c, double fs,
      Color color, FontWeight w) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              fontSize: fs, color: color, fontWeight: w)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}