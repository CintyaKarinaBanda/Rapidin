// ignore_for_file: all
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_add_outlined,
                    size: 80,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Únete a Rapidin',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crea tu cuenta para comenzar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu email';
                      }
                      if (!value.contains('@')) {
                        return 'Ingresa un email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu contraseña';
                      }
                      if (value.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirma tu contraseña';
                      }
                      if (value != _passwordController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (authProvider.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        authProvider.error!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : () async {
                      if (_formKey.currentState!.validate()) {
                        await _showPrivacyDialog();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Crear Cuenta',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: authProvider.isLoading ? null : () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      '¿Ya tienes cuenta? Inicia sesión',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPrivacyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.privacy_tip_outlined, color: Colors.orange),
              SizedBox(width: 8),
              Text('Aviso de Privacidad'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Para crear tu cuenta, necesitas leer y aceptar nuestro Aviso de Privacidad Integral.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Por favor, revisa el documento completo antes de continuar.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final url = Uri.parse('https://docs.google.com/document/d/1UGaz8tFl_V2hPeijvcz4pDf_THkHheMvWBURyqX3tVs/edit?tab=t.0#heading=h.pi87y0g6uvaj');
                try {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No se pudo abrir el enlace')),
                  );
                }
              },
              child: const Text('Leer Aviso', style: TextStyle(color: Colors.blue)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performRegistration();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Acepto'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performRegistration() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await authProvider.signUp(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    
    if (mounted && authProvider.error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro exitoso. Puedes iniciar sesión ahora.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
