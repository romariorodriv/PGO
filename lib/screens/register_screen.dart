import 'package:flutter/material.dart';

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
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo valido')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La contrasena debe tener al menos 6 caracteres'),
        ),
      );
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Debes aceptar los terminos y condiciones')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthService().register(
        name: name,
        email: email,
        password: password,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                _buildLogo(),
                const SizedBox(height: 5),
                Text(
                  'Registrate',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.SecondBlue,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 10),
                _buildSocialButtons(),
                const SizedBox(height: 10),
                Text(
                  'O usa tu correo electronico',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _nameController,
                  hintText: 'Nombre',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Correo electronico',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 16),
                _buildCheckboxes(),
                const SizedBox(height: 24),
                _buildRegisterButton(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Ya tienes una cuenta? ',
                      style: TextStyle(
                        color: AppColors.SecondBlue.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Inicia sesion',
                        style: TextStyle(
                          color: AppColors.PrimaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
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
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.gray),
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
        fillColor: AppColors.SecondBlue.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: AppColors.SecondBlue),
      decoration: InputDecoration(
        hintText: 'Crea una contrasena',
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
        fillColor: AppColors.SecondBlue.withValues(alpha: 0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildCheckboxes() {
    return Column(
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
                activeColor: AppColors.PrimaryGreen,
              ),
              Expanded(
                child: Text(
                  'Recordar usuario',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              _agreeTerms = !_agreeTerms;
            });
          },
          child: Row(
            children: [
              Checkbox(
                value: _agreeTerms,
                onChanged: (value) {
                  setState(() {
                    _agreeTerms = value ?? false;
                  });
                },
                activeColor: AppColors.PrimaryGreen,
              ),
              Expanded(
                child: Text(
                  'He leido y estoy de acuerdo con los terminos y condiciones',
                  style: TextStyle(
                    color: AppColors.SecondBlue.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.PrimaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: _isSubmitting ? null : _handleRegister,
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Registrarse',
                style: TextStyle(
                  color: AppColors.primary,
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
        _buildSocialButton('assets/icons/facebook.png'),
        const SizedBox(width: 20),
        _buildSocialButton('assets/icons/apple.png'),
        const SizedBox(width: 20),
        _buildSocialButton('assets/icons/google.png'),
      ],
    );
  }

  Widget _buildSocialButton(String iconPath) {
    return GestureDetector(
      onTap: () {},
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
        child: const Center(
          child: Icon(
            Icons.share,
            color: AppColors.PrimaryGreen,
          ),
        ),
      ),
    );
  }
}
