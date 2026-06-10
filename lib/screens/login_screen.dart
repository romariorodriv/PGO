import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../utils/post_auth_router.dart';
import 'main_shell.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _userController;
  late TextEditingController _passwordController;

  bool _rememberUser = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;

  @override
  void initState() {
    super.initState();
    _userController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _userController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthService().login(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MainShell.route(),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isGoogleSubmitting = true;
    });

    try {
      await AuthService().loginWithGoogle();
      if (!mounted) return;
      final routed = await routeAfterSuccessfulAuth(context);
      if (!routed && mounted) setState(() {});
    } catch (error) {
      if (!mounted) return;
      if (_isGoogleCancel(error)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSubmitting = false;
        });
      }
    }
  }

  bool _isGoogleCancel(Object error) =>
      error.toString().toLowerCase().contains('cancel');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(),
                const SizedBox(height: 10),
                Text(
                  'Accede con Google',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 31,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Usa tu cuenta de Google para entrar a PGO de forma segura.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue.withValues(alpha: 0.72),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                _SocialAuthButton(
                  label: _isGoogleSubmitting
                      ? 'Conectando...'
                      : 'Continuar con Google',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5F6673),
                  borderColor: const Color(0xFFE7EAF0),
                  icon: const _GoogleGIcon(size: 19),
                  onTap: _isGoogleSubmitting ? null : _handleGoogleLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Center(
        child: Image.asset(
          'assets/images/Logo_Icono.png',
          width: 180,
          height: 180,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      style: const TextStyle(color: AppColors.SecondBlue),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppColors.SecondBlue.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.SecondBlue.withValues(alpha: 0.5),
        ),
        filled: true,
        fillColor:
            backgroundColor ?? AppColors.SecondBlue.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: AppColors.SecondBlue),
      decoration: InputDecoration(
        hintText: 'Contraseña',
        hintStyle: TextStyle(
          color: AppColors.SecondBlue.withValues(alpha: 0.5),
        ),
        prefixIcon: Icon(
          Icons.lock,
          color: AppColors.SecondBlue.withValues(alpha: 0.5),
        ),
        suffixIcon: GestureDetector(
          onTap: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          child: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.SecondBlue.withValues(alpha: 0.5),
          ),
        ),
        filled: true,
        fillColor:
            backgroundColor ?? AppColors.SecondBlue.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildRememberAndForgot() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 4,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _rememberUser = !_rememberUser;
            });
          },
          child: SizedBox(
            width: 170,
            child: Row(
              children: [
                Checkbox(
                  value: _rememberUser,
                  onChanged: (value) {
                    setState(() {
                      _rememberUser = value ?? false;
                    });
                  },
                  activeColor: AppColors.blue,
                ),
                Expanded(
                  child: Text(
                    'Recordar usuario',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.SecondBlue.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ir a recuperar contrasena')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Olvidaste tu contrasena?',
              style: TextStyle(
                color: AppColors.SecondBlue.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.loginGreen,
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        onPressed: _isSubmitting ? null : _handleLogin,
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Ingresar',
                style: TextStyle(
                  color: AppColors.SecondBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildSocialButtons() {
    final disabled = _isGoogleSubmitting;

    return Column(
      children: [
        _SocialAuthButton(
          label: _isGoogleSubmitting ? 'Conectando...' : 'Continuar con Google',
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF5F6673),
          borderColor: const Color(0xFFE7EAF0),
          icon: const _GoogleGIcon(size: 19),
          onTap: disabled ? null : _handleGoogleLogin,
        ),
      ],
    );
  }

  Widget _buildDividerLabel(String label) {
    return Row(
      children: [
        Expanded(
            child:
                Divider(color: AppColors.SecondBlue.withValues(alpha: 0.18))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: AppColors.SecondBlue.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
            child:
                Divider(color: AppColors.SecondBlue.withValues(alpha: 0.18))),
      ],
    );
  }
}

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  static const _rememberEmailKey = 'remembered_login_email';

  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _rememberUser = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _loadRememberedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnack('Completa todos los campos');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthService().login(email: email, password: password);
      await _saveRememberedEmail(email);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MainShell.route(),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_rememberEmailKey) ?? '';
    if (!mounted || email.isEmpty) return;
    setState(() {
      _emailController.text = email;
      _rememberUser = true;
    });
  }

  Future<void> _saveRememberedEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberUser) {
      await prefs.setString(_rememberEmailKey, email);
    } else {
      await prefs.remove(_rememberEmailKey);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 10, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: AppColors.SecondBlue),
              ),
              Center(
                child: Image.asset(
                  'assets/images/Logo_Icono.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Ingresa con email',
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Usa tu correo registrado para volver a PGO.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue.withValues(alpha: 0.68),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _EmailInput(
                controller: _emailController,
                hint: 'Correo electronico',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _EmailPasswordInput(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                hint: 'Contraseña',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _rememberUser,
                    onChanged: (value) =>
                        setState(() => _rememberUser = value ?? false),
                    activeColor: AppColors.PrimaryGreen,
                    checkColor: AppColors.SecondBlue,
                    visualDensity: VisualDensity.compact,
                  ),
                  Expanded(
                    child: Text(
                      'Recordar usuario',
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(
                          initialEmail: _emailController.text.trim(),
                        ),
                      ),
                    ),
                    child: Text(
                      'Olvide mi clave',
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _AuthPrimaryButton(
                label: 'Ingresar',
                loading: _isSubmitting,
                onTap: _isSubmitting ? null : _handleLogin,
              ),
              const SizedBox(height: 18),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: Text(
                    'Crear una cuenta nueva',
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _isSubmitting = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showSnack('Ingresa un correo válido');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await AuthService().forgotPassword(email: email);
      if (!mounted) return;
      setState(() => _sent = true);
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_reset,
                    color: AppColors.SecondBlue, size: 74),
                const SizedBox(height: 22),
                Text(
                  'Recuperacion con Google',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'PGO ahora usa acceso con Google. Para recuperar tu cuenta, usa la recuperacion de Google.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue.withValues(alpha: 0.68),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _AuthPrimaryButton(
                  label: 'Entendido',
                  loading: false,
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmailInput extends StatelessWidget {
  const _EmailInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofillHints: keyboardType == TextInputType.emailAddress
          ? const [AutofillHints.email]
          : null,
      style: GoogleFonts.inter(
        color: AppColors.SecondBlue,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: AppColors.SecondBlue.withValues(alpha: 0.52),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.SecondBlue.withValues(alpha: 0.58),
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.94),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );
  }
}

class _EmailPasswordInput extends StatelessWidget {
  const _EmailPasswordInput({
    required this.controller,
    required this.obscureText,
    required this.onToggle,
    required this.hint,
  });

  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggle;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      autofillHints: const [AutofillHints.password],
      style: GoogleFonts.inter(
        color: AppColors.SecondBlue,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: AppColors.SecondBlue.withValues(alpha: 0.52),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: AppColors.SecondBlue.withValues(alpha: 0.58),
          size: 20,
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.SecondBlue.withValues(alpha: 0.55),
            size: 20,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.94),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );
  }
}

class _AuthPrimaryButton extends StatelessWidget {
  const _AuthPrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  final String label;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.PrimaryGreen,
          disabledBackgroundColor:
              AppColors.PrimaryGreen.withValues(alpha: 0.6),
          foregroundColor: AppColors.SecondBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
      ),
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.onTap,
    this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final Widget icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            decoration: BoxDecoration(
              color: onTap == null
                  ? backgroundColor.withValues(alpha: 0.55)
                  : backgroundColor,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: borderColor ?? Colors.transparent),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(left: 16, child: icon),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: foregroundColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

class _GoogleGIcon extends StatelessWidget {
  const _GoogleGIcon({this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => const SweepGradient(
        startAngle: 0.0,
        endAngle: 6.2831853,
        colors: [
          Color(0xFF4285F4),
          Color(0xFF34A853),
          Color(0xFFFBBC05),
          Color(0xFFEA4335),
          Color(0xFF4285F4),
        ],
      ).createShader(bounds),
      child: Text(
        'G',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: size,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
