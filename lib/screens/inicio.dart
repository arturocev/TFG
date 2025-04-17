import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../metodos_lc/color_lc.dart';
import '../metodos_lc/ordenar_lc.dart';
import '../metodos_lc/get_lc.dart';
import '../metodos_lc/aniadir_lc.dart';
import '../metodos_lc/opciones_lc.dart';
import '../screens/restaurantes.dart';
import '../metodos_per/go_perfil.dart';
import '../metodos_per/cargar_imagen.dart';
import '../metodos_aju/go_ajustes.dart';
import '../screens/perfil.dart';
import '../screens/recetas_screen.dart';

class PantallaPrincipal extends StatefulWidget {
  final int usuarioId;
  final String nombreUsuario;

  const PantallaPrincipal({
    super.key,
    required this.usuarioId,
    required this.nombreUsuario,
    required usuarioNombre,
  });

  @override
  PPEstado createState() => PPEstado();
}

class PPEstado extends State<PantallaPrincipal> {
  List<Map<String, dynamic>> listasCompra = [];
  String? _localImagePath;

  // Clave única para el usuario
  String get _keyProfileImage => 'profile_image_${widget.usuarioId}';

  void irARecetas(BuildContext context, int usuarioId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecetasScreen(usuarioId: usuarioId),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    obtenerListasCompra(context, listasCompra, setState, widget.usuarioId);
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedImagePath = prefs.getString(_keyProfileImage);
    print("🔹 Cargando imagen desde: $savedImagePath");
    setState(() {
      _localImagePath = savedImagePath;
    });
  }

  @override
  Widget build(BuildContext context) {
    ordenarListasCompra(listasCompra);

    // Seleccionar el ImageProvider según la plataforma.
    ImageProvider imageProvider = const AssetImage("assets/avatar.png");
    if (_localImagePath != null && _localImagePath!.isNotEmpty) {
      if (kIsWeb || _localImagePath!.startsWith("http")) {
        imageProvider = NetworkImage(_localImagePath!);
      } else if (File(_localImagePath!).existsSync()) {
        imageProvider = FileImage(File(_localImagePath!));
      }
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFECC099),
            border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
          ),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Padding(
              padding: const EdgeInsets.only(left: 16, top: 15),
              child: Image.asset("assets/logo.png", height: 50),
            ),
            actions: [
              FutureBuilder<String?>(
                future: () async {
                  final prefs = await SharedPreferences.getInstance();
                  return prefs.getString(_keyProfileImage);
                }(),
                builder: (context, snapshot) {
                  ImageProvider imageProvider =
                      const AssetImage("assets/avatar.png");
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    if (kIsWeb || snapshot.data!.startsWith("http")) {
                      imageProvider = NetworkImage(snapshot.data!);
                    } else if (File(snapshot.data!).existsSync()) {
                      imageProvider = FileImage(File(snapshot.data!));
                    }
                  }
                  return GestureDetector(
                    onTap: () async {
                      // Navegar a la pantalla de perfil y esperar el resultado.
                      bool? updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PantallaPerfil(usuarioId: widget.usuarioId),
                        ),
                      );
                      // Si se actualizó la imagen, recargarla.
                      if (updated == true) {
                        _loadSavedImage();
                      }
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: imageProvider,
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0, top: 15),
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Colors.black),
                  onPressed: () => irAAjustes(context, widget.usuarioId),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/fondo1.png", fit: BoxFit.cover),
          ),
          Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: listasCompra.isEmpty
                    ? const Center(child: Text("No hay listas de compra"))
                    : ListView.builder(
                        padding: const EdgeInsets.all(15),
                        itemCount: listasCompra.length,
                        itemBuilder: (context, index) {
                          final lista = listasCompra[index];
                          final colorLista =
                              convertirColor(lista["color"] ?? "#FFCCCBB");
                          return Card(
                            color: colorLista,
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 16),
                            child: ListTile(
                              title: Text(
                                lista["nombre"],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              onTap: () => mostrarOpcionesLista(context, index,
                                  listasCompra, setState, widget.usuarioId),
                            ),
                          );
                        },
                      ),
              ),
              if (listasCompra.length < 25)
                Padding(
                  padding: const EdgeInsets.only(bottom: 110),
                  child: IconButton(
                    icon: const Icon(Icons.add_circle,
                        size: 50, color: Colors.black),
                    onPressed: () => nuevaLC(
                        context, listasCompra, setState, widget.usuarioId),
                  ),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFECC099),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book), label: "Recetas"),
          BottomNavigationBarItem(
              icon: Icon(Icons.restaurant), label: "Restaurantes"),
        ],
        onTap: (index) {
          if (index == 1) {
            // Navegar a la pantalla de recetas
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RecetasScreen(usuarioId: widget.usuarioId),
              ),
            );
          } else if (index == 2) {
            // Navegar a la pantalla de restaurantes
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Restaurantes(usuarioId: widget.usuarioId),
              ),
            );
          }
        },
      ),
    );
  }
}
