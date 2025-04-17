import 'package:shared_preferences/shared_preferences.dart';

// Guarda el ID del usuario en SharedPreferences
Future<void> guardarusuario(int usuarioId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('usuarioId', usuarioId);
}

// Opcional: función para recuperar el ID guardado
Future<int?> obtenerUsuarioId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt('usuarioId');
}
