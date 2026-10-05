import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api.dart';
import '../core/network/api_constants.dart';
import '../session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.session});

  final Session session;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _obscure = true;

  static const _navy = Color(0xFF163A86);
  static const _blue = Color(0xFF1E4F9E);
  static const _welcome = Color(0xFF2E5EAE);
  static const _muted = Color(0xFF7C8DA3);
  static const _line = Color(0xFFD5DEEA);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.session.login(_email.text, _password.text);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Could not reach the server. Check that the API is running.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _LoginBackdropPainter())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 12, 28, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 18),
                        Center(
                          child: Container(
                            width: 132,
                            height: 132,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _navy.withOpacity(0.16),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: ColoredBox(
                                color: Colors.white,
                                child: Transform.scale(
                                  scale: 1.18,
                                  child: Image.asset('assets/logo.jpg', fit: BoxFit.cover),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 26),
                        Row(
                          children: [
                            const Expanded(child: Divider(color: _line, thickness: 1.2)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'CHAPERSONS FOUNDATIONS',
                                style: TextStyle(
                                  color: _navy,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider(color: _line, thickness: 1.2)),
                          ],
                        ),
                        const SizedBox(height: 26),
                        const Text(
                          'Welcome Back',
                          style: TextStyle(color: _welcome, fontSize: 22, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Sign In',
                          style: TextStyle(color: _navy, fontSize: 36, fontWeight: FontWeight.w800, height: 1.1),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Use the email and password created\nin the admin panel.',
                          style: TextStyle(color: _muted, fontSize: 15, height: 1.35),
                        ),
                        const SizedBox(height: 22),
                        _field(
                          controller: _email,
                          hint: 'Email',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.username],
                        ),
                        const SizedBox(height: 14),
                        _field(
                          controller: _password,
                          hint: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscure: _obscure,
                          autofillHints: const [AutofillHints.password],
                          onSubmitted: (_) => _busy ? null : _submit(),
                          suffix: IconButton(
                            onPressed: () => setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: const Color(0xFF8EA0B5),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(_error!, style: const TextStyle(color: Color(0xFF8D2D2D))),
                        ],
                        const SizedBox(height: 22),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: _blue.withOpacity(0.28),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            height: 56,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: _blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              onPressed: _busy ? null : _submit,
                              child: _busy
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.arrow_forward_rounded, size: 22),
                                        SizedBox(width: 14),
                                        SizedBox(height: 22, child: VerticalDivider(color: Colors.white70, thickness: 1)),
                                        SizedBox(width: 14),
                                        Text('Sign In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(child: Divider(color: _line, endIndent: 12)),
                            Icon(Icons.verified_user_outlined, size: 16, color: _muted),
                            SizedBox(width: 6),
                            Text('Secure & Trusted', style: TextStyle(color: _muted, fontSize: 13)),
                            Expanded(child: Divider(color: _line, indent: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            launchUrl(
                              Uri.parse('${ApiConstants.baseUrl}/privacy-policy'),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          child: const Text('Privacy policy'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    Iterable<String>? autofillHints,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      onSubmitted: onSubmitted,
      style: const TextStyle(fontSize: 16, color: Color(0xFF1C2B42)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFA7B4C4)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 8, right: 4),
          child: Icon(icon, color: const Color(0xFF8EA0B5)),
        ),
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE4EBF3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _blue, width: 1.4),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _LoginBackdropPainter extends CustomPainter {
  const _LoginBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()..color = const Color(0xFF1E4F9E);
    final light = Paint()..color = const Color(0xFFD7E6F6);
    final pale = Paint()..color = const Color(0xFFE7F0FA);

    canvas.drawCircle(Offset(-20, -10), size.width * 0.42, blue);
    canvas.drawCircle(Offset(size.width + 30, -30), size.width * 0.38, light);
    canvas.drawCircle(Offset(-10, size.height + 20), size.width * 0.34, pale);
    canvas.drawCircle(Offset(size.width * 0.92, size.height * 0.92), size.width * 0.28, pale);

    final mark = Paint()
      ..color = const Color(0xFFD5E4F4).withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final book = Path()
      ..moveTo(size.width * 0.62, size.height * 0.86)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.80, size.width * 0.96, size.height * 0.88)
      ..moveTo(size.width * 0.62, size.height * 0.86)
      ..quadraticBezierTo(size.width * 0.78, size.height * 0.92, size.width * 0.96, size.height * 0.88);
    canvas.drawPath(book, mark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
