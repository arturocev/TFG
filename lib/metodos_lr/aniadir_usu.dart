import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mandangon/main.dart';

class AgregarUsuario {
  static Future<void> agregarUsuario(BuildContext context, String nombre, String email, String contrasenia, String pregunta, String respuesta) async {
    var url = Uri.parse("http://localhost/mandangon/insertar_datos.php");

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      http.Response respuestaHttp = await http.post(url, body: {
        "nombre": nombre,
        "email": email,
        "contrasenia": contrasenia,
        "pregunta": pregunta,  // Enviar la pregunta de seguridad
        "respuesta": respuesta,  // Enviar la respuesta de seguridad
      });

      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();

      var data = jsonDecode(respuestaHttp.body);

      if (respuestaHttp.statusCode == 200) {
        if (data["error"] == true) {
          // ignore: use_build_context_synchronously
          // ignore: use_build_context_synchronously
          mensaje(context, "Error", data["mensaje"]);
        } else {
           if (contrasenia != "") {
            mensaje(
            // ignore: use_build_context_synchronously
            context,
            "Cuenta Creada",
            "Tu cuenta ha sido creada con éxito. Ahora puedes iniciar sesion.",
            onAceptar: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MandangonApp()),
              );
            },
          );
          }
        }
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al crear la cuenta")),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error de conexión")),
      );
    }
  }

  static void mensaje(BuildContext context, String titulo, String mensaje, {VoidCallback? onAceptar}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onAceptar != null) onAceptar();
            },
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }
}
