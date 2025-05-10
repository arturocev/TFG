import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mandangon/main.dart';

class AgregarUsuario {
  static Future<bool> agregarUsuario(
      BuildContext context,
      String nombre,
      String email,
      String contrasenia,
      String pregunta,
      String respuesta) async {
    var url = Uri.parse("http://localhost/mandangon/insertar_datos.php");

    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Hacer la petición
      http.Response respuestaHttp = await http.post(url, body: {
        "nombre": nombre,
        "email": email,
        "contrasenia": contrasenia,
        "pregunta": pregunta,
        "respuesta": respuesta,
      });

      // Cerrar loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      var data = jsonDecode(respuestaHttp.body);

      if (respuestaHttp.statusCode == 200) {
        if (data["error"] == true) {
          if (context.mounted) {
            _mostrarMensaje(context, "Error", data["mensaje"]);
          }
          return false;
        } else {
          if (context.mounted) {
            if (contrasenia.isNotEmpty) {
              await _mostrarMensaje(context, "Cuenta Creada",
                  "Tu cuenta ha sido creada con éxito. Ahora puedes iniciar sesión.", onAceptar: () {
                Navigator.pop(context); // Cierra cualquier pantalla si es necesario
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MandangonApp()),
                );
              });
            }
          }
          return true; // Usuario creado correctamente
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al crear la cuenta")),
          );
        }
        return false;
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error de conexión")),
        );
      }
      return false;
    }
  }

  static Future<void> _mostrarMensaje(BuildContext context, String titulo,
      String mensaje,
      {VoidCallback? onAceptar}) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (onAceptar != null) {
                onAceptar();
              }
            },
            child: const Text("Aceptar"),
          ),
        ],
      ),
    );
  }
}