import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para los campos de texto
  late TextEditingController _userController;
  late TextEditingController _passwordController;
  
  // Variable para el checkbox
  bool _rememberUser = false;
  
  // Variable para mostrar/ocultar contraseña
  bool _obscurePassword = true;

  //Inicializacion de controladores o recursos
  @override
  void initState() {
    super.initState();
    _userController = TextEditingController();
    _passwordController = TextEditingController();
  }

  //Liberacion de controladores o recursos
  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
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
              AppColors.primary,
              AppColors.primaryDark,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.08),
                
                // Logo PGO
                _buildLogo(),
                
                SizedBox(height: 40),
                
                // Título
                Text(
                  'Inicia sesión',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                
                SizedBox(height: 30),
                
                // Campo Usuario
                _buildTextField(
                  controller: _userController,
                  hintText: 'Usuario o correo electrónico',
                  icon: Icons.person,
                  borderRadius: BorderRadius.circular(30),
                  backgroundColor: AppColors.white.withOpacity(0.1),
                ),
                
                SizedBox(height: 16),
                
                // Campo Contraseña
                _buildPasswordField(
                  borderRadius: BorderRadius.circular(30),
                  backgroundColor: AppColors.white.withOpacity(0.1),
                ),
                
                SizedBox(height: 16),
                
                // Recordar usuario y Olvidaste contraseña
                _buildRememberAndForgot(),
                
                SizedBox(height: 24),
                
                // Botón Ingresar
                _buildLoginButton(),
                
                SizedBox(height: 32),
                
                // Texto "Inicia sesión con"
                Text(
                  'Inicia sesión con',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                
                SizedBox(height: 16),
                
                // Botones sociales
                _buildSocialButtons(),
                
                SizedBox(height: 24),
                
                // Link Registrarse
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿No tienes una cuenta? ',
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.7),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Registrate',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget para el logo
  Widget _buildLogo() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Image.asset(
          'assets/images/logo_login.png',
          width: 180,
          height: 180,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // Widget para campos de texto normales
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppColors.white.withOpacity(0.5),
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.white.withOpacity(0.5),
        ),
        filled: true,
        fillColor: backgroundColor ?? AppColors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // Widget para campo de contraseña
  Widget _buildPasswordField({
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        hintText: 'Contraseña',
        hintStyle: TextStyle(
          color: AppColors.white.withOpacity(0.5),
        ),
        prefixIcon: Icon(
          Icons.lock,
          color: AppColors.white.withOpacity(0.5),
        ),
        suffixIcon: GestureDetector(
          onTap: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          child: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppColors.white.withOpacity(0.5),
          ),
        ),
        filled: true,
        fillColor: backgroundColor ?? AppColors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // Widget para recordar usuario y olvidaste contraseña
  Widget _buildRememberAndForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Checkbox Recordar usuario
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
                activeColor: AppColors.secondary,
              ),
              Text(
                'Recordar usuario',
                style: TextStyle(
                  color: AppColors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        // Link Olvidaste contraseña
        GestureDetector(
          onTap: () {
            // Aquí irá la navegación a recuperar contraseña
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ir a Recuperar Contraseña')),
            );
          },
          child: Text(
            'Olvidaste tu contraseña?',
            style: TextStyle(
              color: AppColors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Widget para el botón de ingresar
  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: () {
          // Aquí va la lógica de login
          String user = _userController.text;
          String password = _passwordController.text;
          
          if (user.isEmpty || password.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Completa todos los campos')),
            );
          } else {
            // Navegar al HomeScreen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        },
        child: Text(
          'Ingresar',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Widget para botones sociales
  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialButton('assets/icons/facebook.png'),
        SizedBox(width: 20),
        _buildSocialButton('assets/icons/apple.png'),
        SizedBox(width: 20),
        _buildSocialButton('assets/icons/google.png'),
      ],
    );
  }

  // Widget para cada botón social
  Widget _buildSocialButton(String iconPath) {
    return GestureDetector(
      onTap: () {
        // Lógica de login social
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.white.withOpacity(0.2),
          ),
        ),
        child: Center(
          // Por ahora usamos un icono, después agregaremos imágenes
          child: Icon(
            Icons.share,
            color: AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
