import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/auth_service.dart';
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
      Navigator.of(context).pushReplacement(
        MainShell.route(),
      );
    } catch (error) {
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryDark,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildLogo(),
                const SizedBox(height: 10),
                Text(
                  'Inicia sesion',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.SecondBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  controller: _userController,
                  hintText: 'Correo electronico',
                  icon: Icons.person,
                  borderRadius: BorderRadius.circular(30),
                  backgroundColor: AppColors.primary,
                ),
                const SizedBox(height: 5),
                _buildPasswordField(
                  borderRadius: BorderRadius.circular(30),
                  backgroundColor: AppColors.primary,
                ),
                const SizedBox(height: 5),
                _buildRememberAndForgot(),
                const SizedBox(height: 10),
                _buildLoginButton(),
                const SizedBox(height: 32),
                Text(
                  'Inicia sesion con',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                _buildSocialButtons(),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No tienes una cuenta? ',
                      style: TextStyle(color: AppColors.PrimaryGreen),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Registrate',
                        style: TextStyle(
                          color: AppColors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
        hintText: 'Contrasena',
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _rememberUser = !_rememberUser;
            });
          },
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
              Text(
                'Recordar usuario',
                style: TextStyle(
                  color: AppColors.SecondBlue.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ir a Recuperar Contrasena')),
            );
          },
          child: Text(
            'Olvidaste tu contrasena?',
            style: TextStyle(
              color: AppColors.SecondBlue.withValues(alpha: 0.7),
              fontSize: 12,
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
          backgroundColor: AppColors.PrimaryGreen,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton(
          label: 'F',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Facebook aun no esta disponible')),
            );
          },
        ),
        const SizedBox(width: 20),
        _buildSocialButton(
          label: 'A',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Apple aun no esta disponible')),
            );
          },
        ),
        const SizedBox(width: 20),
        _buildSocialButton(
          label: _isGoogleSubmitting ? '...' : 'G',
          onTap: _isSubmitting || _isGoogleSubmitting ? null : _handleGoogleLogin,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.SecondBlue.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.SecondBlue.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
