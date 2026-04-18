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
              const SizedBox(height: 14),
              Text(
                'O usa tu correo electronico',
                style: GoogleFonts.inter(
                  color: AppColors.SecondBlue.withValues(alpha: 0.82),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              _buildInput(
                controller: _nameController,
                hint: 'Nombre',
              ),
              const SizedBox(height: 12),
              _buildInput(
                controller: _emailController,
                hint: 'Correo electronico',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              _buildPasswordInput(),
              const SizedBox(height: 8),
              _buildCheckboxRow(
                value: _rememberUser,
                onChanged: (value) => setState(() => _rememberUser = value),
                text: 'Recordar usuario',
              ),
              const SizedBox(height: 2),
              _buildCheckboxRow(
                value: _agreeTerms,
                onChanged: (value) => setState(() => _agreeTerms = value),
                text: 'He leido y estoy de acuerdo con los terminos y condiciones',
              ),
              const SizedBox(height: 14),
              _buildRegisterButton(),
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
                      'Inicia sesion',
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialCircleButton(
          backgroundColor: Colors.white,
          onTap: disabled ? null : _handleGoogleRegister,
          icon: _isGoogleSubmitting
              ? Text(
                  '...',
                  style: GoogleFonts.inter(
                    color: AppColors.SecondBlue,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : const _GoogleGIcon(),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
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
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
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
        onPressed: _isSubmitting || _isGoogleSubmitting ? null : _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.PrimaryGreen,
          disabledBackgroundColor: AppColors.PrimaryGreen.withValues(alpha: 0.6),
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

class _SocialCircleButton extends StatelessWidget {
  const _SocialCircleButton({
    required this.backgroundColor,
    required this.icon,
    this.onTap,
  });

  final Color backgroundColor;
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
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}

class _GoogleGIcon extends StatelessWidget {
  const _GoogleGIcon();

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
          fontSize: 33,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
