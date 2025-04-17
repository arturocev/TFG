import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart'; // Para mostrar alertas o diálogos

// Método para consultar el inicio de sesión
Future<Map<String, dynamic>?> inicioSesion(
    String email, String pass, BuildContext context) async {
  var url = Uri.parse(
      "http://localhost/mandangon/consultar_datos.php?email=$email&pass=$pass");

  if (kDebugMode) {
    print("URL de consulta: \$url");
  }

  http.Response consulta = await http.get(url);

  if (kDebugMode) {
    print("Código de estado de la respuesta: \${consulta.statusCode}");
    print("Respuesta del servidor: \${consulta.body}");
  }

  if (consulta.statusCode == 200) {
    try {
      final respuesta = jsonDecode(consulta.body);

      if (respuesta['error'] == true) {
        if (kDebugMode) {
          print("Error en la respuesta del servidor: \${respuesta['mensaje']}");
        }

        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text("Error de Inicio de Sesión"),
            content: Text(respuesta['mensaje']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Aceptar"),
              ),
            ],
          ),
        );

        return null;
      } else {
        final usuarioId = int.tryParse(respuesta['id'].toString());
        final usuarioNombre =
            respuesta['nombre'].toString(); // Obtener el nombre

        if (usuarioId != null) {
          return {
            'id': usuarioId,
            'nombre': usuarioNombre
          }; // Devolver mapa con ID y nombre
        } else {
          if (kDebugMode) {
            print("Error: El ID recibido no es un número válido.");
          }
          return null;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al procesar la respuesta: \$e");
      }
      return null;
    }
  } else {
    if (kDebugMode) {
      print("Conexión fallida: \${consulta.statusCode}");
    }
    return null;
  }
}
