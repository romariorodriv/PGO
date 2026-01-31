import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores para los campos de texto
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  // Variables para checkboxes
  bool _rememberUser = false;
  bool _agreeTerms = false;

  // Variable para mostrar/ocultar contraseña
  bool _obscurePassword = true;

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
                SizedBox(height: MediaQuery.of(context).size.height * 0.06),

                // Logo PGO
                _buildLogo(),

                SizedBox(height: 32),

                // Título
                Text(
                  'Registrate',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),

                SizedBox(height: 24),

                // Botones sociales
                _buildSocialButtons(),

                SizedBox(height: 24),

                // Texto "O usa tu correo electrónico"
                Text(
                  'O usa tu correo electrónico',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),

                SizedBox(height: 20),

                // Campo Nombre
                _buildTextField(
                  controller: _nameController,
                  hintText: 'Nombre',
                  icon: Icons.person,
                ),

                SizedBox(height: 16),

                // Campo Email
                _buildTextField(
                  controller: _emailController,
                  hintText: 'Correo electrónico',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: 16),

                // Campo Contraseña
                _buildPasswordField(),

                SizedBox(height: 16),

                // Checkboxes
                _buildCheckboxes(),

                SizedBox(height: 24),

                // Botón Registrarse
                _buildRegisterButton(),

                SizedBox(height: 16),

                // Link para ir a login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes una cuenta? ',
                      style: TextStyle(
                        color: AppColors.white.withOpacity(0.7),
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
                      child: Text(
                        'Inicia sesión',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withOpacity(0.2),
              ),
              child: Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget para campos de texto normales
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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
        fillColor: AppColors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
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
  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(color: AppColors.white),
      decoration: InputDecoration(
        hintText: 'Crea una contraseña',
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
        fillColor: AppColors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  // Widget para checkboxes
  Widget _buildCheckboxes() {
    return Column(
      children: [
        // Checkbox 1: Recordar usuario
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
              Expanded(
                child: Text(
                  'Recordar usuario',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Checkbox 2: Términos y condiciones
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
                activeColor: AppColors.secondary,
              ),
              Expanded(
                child: Text(
                  'He leído y estoy de acuerdo con los términos y condiciones',
                  style: TextStyle(
                    color: AppColors.white.withOpacity(0.7),
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

  // Widget para el botón de registrarse
  Widget _buildRegisterButton() {
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
          // Validar campos
          String name = _nameController.text;
          String email = _emailController.text;
          String password = _passwordController.text;

          if (name.isEmpty || email.isEmpty || password.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Completa todos los campos')),
            );
          } else if (!email.contains('@')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ingresa un correo válido')),
            );
          } else if (password.length < 6) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
            );
          } else if (!_agreeTerms) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Debes aceptar los términos y condiciones')),
            );
          } else {
            // Aquí va la lógica de registro (por ahora solo mostramos un mensaje)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('¡Registro exitoso!')),
            );
            // Después navegar al login
            Future.delayed(Duration(seconds: 2), () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            });
          }
        },
        child: Text(
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
        // Lógica de registro social
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
          child: Icon(
            Icons.share,
            color: AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
