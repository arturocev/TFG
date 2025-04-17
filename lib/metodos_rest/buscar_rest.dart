import 'aleatorio_rest.dart';

void buscarRestaurantes(String query, List<dynamic> todosRestaurantes,
    Function setState, List<dynamic> listaVisible) {
  final resultados = todosRestaurantes.where((rest) {
    final nombre = rest['rest_nom'].toString().toLowerCase();
    final tipo = rest['rest_tipo_com'].toString().toLowerCase();
    final ubicacion = rest['rest_ubi'].toString().toLowerCase();
    final q = query.toLowerCase();
    return nombre.contains(q) || tipo.contains(q) || ubicacion.contains(q);
  }).toList();

  setState(() {
    listaVisible.clear(); // LIMPIAMOS PRIMERO
    if (query.isEmpty) {
      listaVisible.addAll(
          obtenerAleatorios(todosRestaurantes, 10)); // Añadimos aleatorios
    } else {
      listaVisible.addAll(resultados); // Añadimos resultados filtrados
    }
  });
}
