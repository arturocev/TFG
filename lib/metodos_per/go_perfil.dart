// go_perfil.dart
import 'package:flutter/material.dart';
import 'package:mandangon/metodos_aju/go_ajustes.dart';
import 'package:mandangon/screens/perfil.dart'; // Asegúrate de tener esta clase en la ubicación correcta.

void irAPerfil(BuildContext context, int usuarioId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PantallaPerfil(usuarioId: usuarioId),
    ),
  );
}
