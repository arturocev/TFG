import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:mandangon/main.dart';

class AjustesScreen extends StatefulWidget {
  final int userId;

  const AjustesScreen({super.key, required this.userId});

  @override
  State<AjustesScreen> createState() => _AjustesScreenState();
}

class _AjustesScreenState extends State<AjustesScreen> {
  bool _showChangePassword = false;
  bool _isLoading = false;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  void logMessage(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  void _toggleChangePassword() {
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      _showChangePassword = !_showChangePassword;
    });
  }

  Future<void> _updatePassword() async {
    String newPassword = _newPasswordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (newPassword.length < 8 || newPassword.length > 12) {
      _showMessage("La contraseña debe tener entre 8 y 12 caracteres.");
      return;
    }
    if (newPassword != confirmPassword) {
      _showMessage("Las contraseñas no coinciden.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await http.post(
        Uri.parse('http://localhost/mandangon/cambiar_contrasenia.php'),
        body: {
          'id_usu': widget.userId.toString(),
          'new_password': newPassword,
        },
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        _showMessage("Contraseña actualizada con éxito.");
        _toggleChangePassword();
      } else {
        _showMessage("Error al actualizar la contraseña.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage("Error de red. Intenta de nuevo.");
      logMessage("Error actualizar contraseña: $e");
    }
  }

  Future<void> _deleteAccount() async {
    bool confirmDelete = await _showDeleteConfirmation();
    if (!confirmDelete) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var response = await http.post(
        Uri.parse('http://localhost/mandangon/eliminar_cuenta.php'),
        body: {
          'id_usu': widget.userId.toString(),
        },
      ).timeout(const Duration(seconds: 10));

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        _showMessage("Cuenta eliminada con éxito.");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MandangonApp()),
          (route) => false,
        );
      } else {
        _showMessage("Error al eliminar la cuenta.");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage("Error de red. Intenta de nuevo.");
      logMessage("Error eliminar cuenta: $e");
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirmar eliminación"),
            content: const Text("¿Estás seguro que quieres eliminar tu cuenta?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ?? false;
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Términos de la empresa"),
        content: SingleChildScrollView(
          child: Text(
            '''Última actualización: [06/03/2025]
 Bienvenido a Mandangon. Antes de utilizar nuestros servicios, te pedimos que leas y aceptes los siguientes términos y condiciones\n"
            "1. Definiciones\n"
            "- Plataforma: Aplicación móvil y web de Mandangon que permite a los usuarios acceder a recetas y localizar restaurantes cercanos.\n"
            "- Usuario: Persona que utiliza la plataforma para visualizar recetas o encontrar restaurantes.\n"
            "- Restaurante asociado: Establecimiento que proporciona información sobre su ubicación, contacto y servicios.\n"
            "2. Uso de la Plataforma\n"
            "- Se prohíbe el uso de la plataforma para actividades fraudulentas o ilegales.\n"
            "- Mandangon no es responsable de la disponibilidad o calidad de los productos de los restaurantes ni de los ingredientes de las recetas.\n"
            "3. Recetas\n"
            "- Cada receta incluye una imagen, una lista de ingredientes y pasos detallados de preparación.\n"
            "- La información proporcionada es orientativa y puede variar según los ingredientes o la preparación.\n"
            "- [Mandangon] no se responsabiliza por alergias o problemas de salud derivados del consumo de los platos preparados.\n"
            "4. Restaurantes Cercanos\n"
            "- La plataforma muestra restaurantes basados en la ubicación del usuario.\n"
            "- Cada restaurante puede incluir información como dirección, teléfono, horario y servicios disponibles.\n"
            "- Mandangon no garantiza la exactitud de la información ni la disponibilidad de los servicios en los restaurantes listados.\n"
            "5. Responsabilidad y Limitaciones\n"
            "- Mandangon actúa como intermediario y no es responsable por problemas en la información de recetas o restaurantes.\n"
            "- No garantizamos la disponibilidad constante de la plataforma y nos reservamos el derecho de modificar o suspender servicios en cualquier momento.\n"
            "6. Modificaciones de los Términos\n"
            "- Nos reservamos el derecho de modificar estos términos cuando sea necesario.\n"
            "- El uso continuado de la plataforma después de los cambios implica la aceptación de los nuevos términos.\n"
            "Si tienes dudas, contáctanos en soporte@mandangon.com.'''
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Política de privacidad"),
        content: SingleChildScrollView(
          child: Text(
            '''Última actualización: [06/03/2025]
  En Mandangon, nos tomamos muy en serio la privacidad de nuestros usuarios. Esta Política de Privacidad describe cómo recopilamos, usamos y protegemos tu información personal cuando utilizas nuestra aplicación.\n"
            "1. Información que Recopilamos\n"
            "- Información personal: Nombre, correo electrónico, teléfono (si decides registrarte).\n"
            "- Datos de uso: Información sobre cómo interactúas con la aplicación, como recetas consultadas o restaurantes visitados.\n"
            "2. Uso de la Información\n"
            "- Ofrecerte una mejor experiencia, permitiéndote acceder a recetas y restaurantes cercanos de manera personalizada.\n"
            "- Mejorar nuestra plataforma mediante análisis del comportamiento de los usuarios.\n"
            "- Enviarte notificaciones sobre actualizaciones o promociones (si decides aceptarlas).\n"
            "3. Compartición de Datos\n"
            "- No vendemos ni compartimos tu información personal con terceros, salvo en los siguientes casos:\n"
            "  - Con proveedores de servicios que nos ayudan a operar la plataforma (por ejemplo, servidores de almacenamiento).\n"
            "  - Si es requerido por ley o por una solicitud legal válida.\n"
            "4. Seguridad de la Información\n"
            "- Implementamos medidas de seguridad para proteger tu información, pero no podemos garantizar una seguridad absoluta. Se recomienda no compartir datos sensibles en la plataforma.\n"
            "5. Permisos y Control de Datos\n"
            "- Puedes gestionar los permisos otorgados a la aplicación en los ajustes de tu dispositivo. También puedes:\n"
            "  - Modificar o eliminar tu cuenta en cualquier momento.\n"
            "  - Desactivar el acceso a la ubicación desde los ajustes del teléfono.\n"
            "  - Solicitar la eliminación de tus datos contactándonos en soporte@mandangon.com.\n"
            "6. Cambios en la Política de Privacidad\n"
            "- Nos reservamos el derecho de modificar esta política en cualquier momento. Te notificaremos sobre cambios importantes a través de la aplicación.\n"
            "Si tienes dudas, contáctanos en soporte@mandangon.com.'''
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ajustes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_showChangePassword) {
              setState(() {
                _showChangePassword = false;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/fondo1.jpg'), // tu fondo de inicio
            fit: BoxFit.cover,
          ),
        ),
        child: _showChangePassword
            ? Padding(
                padding: const EdgeInsets.only(top: 100.0, left: 16.0, right: 16.0, bottom: 16.0), // Ajuste aquí
                child: Column(
                  children: [
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: "Nueva contraseña",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: "Confirmar contraseña",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _updatePassword,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Colors.deepOrange,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Confirmar"),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.only(top: 100.0, left: 16.0, right: 16.0, bottom: 16.0), // Ajuste aquí también
                children: [
                  _buildCard(Icons.lock, "Cambiar contraseña", _toggleChangePassword),
                  _buildCard(Icons.article, "Términos de la empresa", _showTermsAndConditions),
                  _buildCard(Icons.privacy_tip, "Política de privacidad", _showPrivacyPolicy),
                  _buildCard(Icons.delete_forever, "Eliminar cuenta", _deleteAccount, color: Colors.red),
                  _buildCard(Icons.logout, "Cerrar sesión", _logout),
                ],
              ),
      ),
    );
  }

  Widget _buildCard(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: color ?? Colors.deepOrange),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _logout() {
    _showMessage("Se ha cerrado la sesión");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MandangonApp()),
      (route) => false,
    );
  }
}
