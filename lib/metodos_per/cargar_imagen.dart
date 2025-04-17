import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String?> cargarImagenPerfil(int usuarioId) async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'profile_image_$usuarioId';
  final savedImagePath = prefs.getString(key);
  if (kIsWeb) {
    return (savedImagePath != null && savedImagePath.isNotEmpty)
        ? savedImagePath
        : null;
  } else {
    if (savedImagePath != null &&
        savedImagePath.isNotEmpty &&
        File(savedImagePath).existsSync()) {
      return savedImagePath;
    }
  }
  return null;
}
