import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../screens/crear_receta_screen.dart';

class RecetasScreen extends StatefulWidget {
  final int usuarioId;

  const RecetasScreen({super.key, required this.usuarioId});

  @override
  RecetasScreenState createState() => RecetasScreenState();
}

class RecetasScreenState extends State<RecetasScreen> {
  // Lista para almacenar las recetas
  List<Map<String, String>> recetas = [];

  @override
  void initState() {
    super.initState();
    obtenerRecetas();
  }

  Future<void> obtenerRecetas() async {
    // Usar el ID del usuario recibido en el constructor
    final int usuarioId = widget.usuarioId;
    final String url =
        'http://localhost/mandangon/obtener_recetas.php?usuario_id=$usuarioId';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        List<dynamic> datos = json.decode(response.body);
        setState(() {
          recetas = datos
              .map((receta) {
                return {
                  'id_rec': receta['id_rec'].toString(),
                  'titulo': receta['rec_nom'] ?? '',
                  'tipo': receta['rec_tipo_com'] ?? '',
                  'ingredientes': receta['rec_ing'] ?? '',
                  'instrucciones': receta['rec_desc'] ?? '',
                  'tiempo': receta['rec_tmp'] ?? '',
                  'rec_img': receta['rec_img'] ?? '',
                };
              })
              .toList()
              .map<Map<String, String>>(
                  (element) => Map<String, String>.from(element))
              .toList();
        });
      } else {
        print("Error al obtener recetas: ${response.statusCode}");
      }
    } catch (error) {
      print("Error al obtener recetas: $error");
    }
  }

  // Función para agregar una nueva receta
  void agregarReceta() async {
    // Navega a la pantalla CrearRecetaScreen y espera la receta creada
    final nuevaReceta = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CrearRecetaScreen()),
    );

    // Si la receta no es nula, la agrega a la lista de recetas
    if (nuevaReceta != null) {
      setState(() {
        recetas.add(nuevaReceta);
      });
    }
  }

  // Función para eliminar una receta utilizando el nombre (título)
  Future<void> eliminarReceta(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmar eliminación"),
          content: Text("¿Estás seguro de que deseas eliminar esta receta?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Cierra el diálogo de confirmación

                String? nombreReceta = recetas[index]['titulo'];
                if (nombreReceta == null || nombreReceta.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Nombre de receta no válido")),
                  );
                  return;
                }

                // Llamar a la API para eliminar la receta usando el nombre
                bool eliminada =
                    await eliminarRecetaDesdeServidor(nombreReceta);

                if (eliminada) {
                  setState(() {
                    recetas.removeAt(index);
                  });
                }
              },
              child: Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  // Función que se comunica con el servidor para eliminar una receta por nombre
  Future<bool> eliminarRecetaDesdeServidor(String titulo) async {
    final String url = 'http://localhost/mandangon/eliminar_receta.php';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {
          'rec_nom': titulo,
          'rec_usu': widget.usuarioId.toString(),
        },
      );

      final responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                responseData['message'] ?? 'Receta eliminada correctamente'),
          ),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(responseData['message'] ?? 'Error al eliminar la receta'),
          ),
        );
        return false;
      }
    } catch (error) {
      print("Error al eliminar la receta: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión con el servidor')),
      );
      return false;
    }
  }

  // Función para mostrar las opciones (editar, ver descripción, eliminar) de una receta
  void mostrarOpciones(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Opciones"),
          content: Text("¿Qué quieres hacer con esta receta?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                editarReceta(index);
              },
              child: Text("Editar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                verDescripcion(index);
              },
              child: Text("Ver Descripción"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                eliminarReceta(index);
              },
              child: Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  // Función para editar una receta
  void editarReceta(int index) async {
    final recetaEditada = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearRecetaScreen(receta: recetas[index]),
      ),
    );

    // Si la receta ha sido editada, se actualiza en la lista
    if (recetaEditada != null) {
      setState(() {
        recetas[index] = recetaEditada;
      });
    }
  }

  void verDescripcion(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(recetas[index]['titulo']!),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Tipo: ${recetas[index]['tipo']}"),
                SizedBox(height: 10),
                Text("Ingredientes: ${recetas[index]['ingredientes']}"),
                SizedBox(height: 10),
                Text("Instrucciones: ${recetas[index]['instrucciones']}"),
                SizedBox(height: 10),
                Text("Tiempo estimado: ${recetas[index]['tiempo']}"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cerrar"),
            ),
          ],
        );
      },
    );
  }

  Widget mostrarImagen(String? path) {
    if (path == null || path.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        color: Colors.grey[300],
        child: Icon(Icons.image, color: Colors.grey[700]),
      );
    }

    String baseUrl = "http://localhost/mandangon/";
    String imageUrl;
    if (path.startsWith("http")) {
      imageUrl = path;
    } else if (path.startsWith("uploads/")) {
      imageUrl = baseUrl + path;
    } else {
      imageUrl = baseUrl + "uploads/" + path;
    }

    if (kIsWeb) {
      return Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover);
    } else {
      return Image.file(File(imageUrl),
          width: 50, height: 50, fit: BoxFit.cover);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [],
      ),
      extendBodyBehindAppBar: true, // Para que el fondo ocupe toda la pantalla
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/fondoINC.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color.fromARGB(255, 247, 199, 67),
                  child: Center(
                    child: Text(
                      "Error al cargar la imagen",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                );
              },
            ),
          ),
          // Contenido de la pantalla
          Column(
            children: [
              SizedBox(height: 100), // Espaciado para el logo
              Image.asset(
                'assets/logo.png',
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    color: Colors.red,
                    child: Center(child: Text("Error al cargar logo")),
                  );
                },
              ),
              Expanded(
                child: recetas.isEmpty
                    ? Center(
                        child: Text(
                          "No hay recetas disponibles",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: recetas.length,
                        itemBuilder: (context, index) {
                          return Card(
                            color: const Color.fromARGB(255, 102, 21, 21),
                            child: ListTile(
                              leading: mostrarImagen(recetas[index]['rec_img']),
                              title: Text(
                                recetas[index]['titulo']!,
                                style: TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                recetas[index]['tipo']!,
                                style: TextStyle(color: Colors.white70),
                              ),
                              onTap: () => mostrarOpciones(index),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: agregarReceta,
        child: const Icon(Icons.add),
      ),
    );
  }
}
