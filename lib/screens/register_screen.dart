import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _rememberUser = false;
  bool _agreeTerms = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack('Completa todos los campos');
      return;
    }

    if (!email.contains('@')) {
      _showSnack('Ingresa un correo valido');
      return;
    }

    if (password.length < 6) {
      _showSnack('La contrasena debe tener al menos 6 caracteres');
      return;
    }

    if (!_agreeTerms) {
      _showSnack('Debes aceptar los terminos y condiciones');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await AuthService().register(
        name: name,
        email: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MainShell.route());
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleGoogleRegister() async {
    setState(() => _isGoogleSubmitting = true);
    try {
      await AuthService().loginWithGoogle();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MainShell.route());
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isGoogleSubmitting = false);
      }
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
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Image.asset(
                'assets/images/Logo_Icono.png',
                width: 170,
                height: 170,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 4),
              Text(
                'Registrate',
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 18),
              _buildSocialButtons(),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ya tienes una cuenta? ',
                    style: GoogleFonts.inter(
                      color: AppColors.SecondBlue.withValues(alpha: 0.75),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: Text(
                      'Inicia sesión',
                      style: GoogleFonts.inter(
                        color: AppColors.SecondBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButtons() {
    final disabled = _isSubmitting || _isGoogleSubmitting;

    return Column(
      children: [
        _SocialAuthButton(
          label: _isGoogleSubmitting ? 'Conectando...' : 'Sign up with Google',
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF5F6673),
          borderColor: const Color(0xFFE7EAF0),
          onTap: disabled ? null : _handleGoogleRegister,
          icon: _isGoogleSubmitting
              ? Text(
                  '',
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : const _GoogleGIcon(size: 19),
        ),
        const SizedBox(height: 8),
        _SocialAuthButton(
          label: 'Sign up with Facebook',
          backgroundColor: const Color(0xFF1877F2),
          foregroundColor: Colors.white,
          icon: const Text(
            'f',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          onTap: disabled
              ? null
              : () {
                  _showSnack('Facebook aún no esta disponible');
                },
        ),
        const SizedBox(height: 8),
        _SocialAuthButton(
          label: 'Sign up with email',
          backgroundColor: Colors.white,
          foregroundColor: AppColors.SecondBlue,
          borderColor: const Color(0xFFD8DDE6),
          icon: Icon(
            Icons.mail_outline,
            size: 17,
            color: AppColors.SecondBlue.withValues(alpha: 0.7),
          ),
          onTap: disabled
              ? null
              : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EmailRegisterScreen(),
                    ),
                  );
                },
        ),
      ],
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        color: AppColors.SecondBlue,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: AppColors.SecondBlue.withValues(alpha: 0.55),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      ),
    );
  }

  Widget _buildPasswordInput() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: GoogleFonts.inter(
        color: AppColors.SecondBlue,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: 'Crea una contrasena',
        hintStyle: GoogleFonts.inter(
          color: AppColors.SecondBlue.withValues(alpha: 0.55),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        suffixIcon: IconButton(
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.SecondBlue.withValues(alpha: 0.55),
            size: 20,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.92),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      ),
    );
  }

  Widget _buildCheckboxRow({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String text,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              side: BorderSide(
                color: AppColors.SecondBlue.withValues(alpha: 0.38),
                width: 1.2,
              ),
              activeColor: AppColors.PrimaryGreen,
              checkColor: AppColors.SecondBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue.withValues(alpha: 0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed:
            _isSubmitting || _isGoogleSubmitting ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.PrimaryGreen,
          disabledBackgroundColor:
              AppColors.PrimaryGreen.withValues(alpha: 0.6),
          foregroundColor: AppColors.SecondBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                'Registrarse',
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
      ),
    );
  }
}

class EmailRegisterScreen extends StatefulWidget {
  const EmailRegisterScreen({super.key});

  @override
  State<EmailRegisterScreen> createState() => _EmailRegisterScreenState();
}

class _EmailRegisterScreenState extends State<EmailRegisterScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  bool _rememberUser = false;
  bool _agreeTerms = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnack('Completa todos los campos');
      return;
    }

    if (!email.contains('@')) {
      _showSnack('Ingresa un correo valido');
      return;
    }

    if (password.length < 6) {
      _showSnack('La contrasena debe tener al menos 6 caracteres');
      return;
    }

    if (!_agreeTerms) {
      _showSnack('Debes aceptar los terminos y condiciones');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await AuthService().register(
        name: name,
        email: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MainShell.route(),
        (_) => false,
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
                  width: 142,
                  height: 142,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Registrate con email',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Crea tu cuenta y empieza a registrar tus partidos.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue.withValues(alpha: 0.68),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _RegisterInput(
                controller: _nameController,
                hint: 'Nombre',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),
              _RegisterInput(
                controller: _emailController,
                hint: 'Correo electrónico',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _RegisterPasswordInput(
                controller: _passwordController,
                obscureText: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              const SizedBox(height: 10),
              _RegisterCheckRow(
                value: _rememberUser,
                onChanged: (value) => setState(() => _rememberUser = value),
                text: 'Recordar usuario',
              ),
              const SizedBox(height: 4),
              _RegisterCheckRow(
                value: _agreeTerms,
                onChanged: (value) => setState(() => _agreeTerms = value),
                text: 'He leido y acepto los terminos y condiciones de PGO.',
              ),
              const SizedBox(height: 18),
              _RegisterPrimaryButton(
                label: 'Crear cuenta',
                loading: _isSubmitting,
                onTap: _isSubmitting ? null : _handleRegister,
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const EmailLoginScreen()),
                  ),
                  child: Text(
                    'Ya tengo una cuenta',
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

class _RegisterInput extends StatelessWidget {
  const _RegisterInput({
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

class _RegisterPasswordInput extends StatelessWidget {
  const _RegisterPasswordInput({
    required this.controller,
    required this.obscureText,
    required this.onToggle,
  });

  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      autofillHints: const [AutofillHints.newPassword],
      style: GoogleFonts.inter(
        color: AppColors.SecondBlue,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: 'Crea una contrasena',
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

class _RegisterCheckRow extends StatelessWidget {
  const _RegisterCheckRow({
    required this.value,
    required this.onChanged,
    required this.text,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String text;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (selected) => onChanged(selected ?? false),
            activeColor: AppColors.PrimaryGreen,
            checkColor: AppColors.SecondBlue,
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: AppColors.SecondBlue.withValues(alpha: 0.78),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterPrimaryButton extends StatelessWidget {
  const _RegisterPrimaryButton({
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: double.infinity,
          height: 34,
          decoration: BoxDecoration(
            color: onTap == null
                ? backgroundColor.withValues(alpha: 0.82)
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
