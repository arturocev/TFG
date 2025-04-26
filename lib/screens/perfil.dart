import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PantallaPerfil extends StatefulWidget {
  final int usuarioId;

  const PantallaPerfil({super.key, required this.usuarioId});

  @override
  PantallaPerfilState createState() => PantallaPerfilState();
}

class PantallaPerfilState extends State<PantallaPerfil> {
  final ImagePicker _picker = ImagePicker();
  String? imgLocal;
  String _userName = 'Sin usuario';
  final String urlServidor = "http://localhost/mandangon";
  bool _updated = false;

  String get _keyNombreUsuario => 'nombre_usuario_${widget.usuarioId}';
  String get _keyProfileImage => 'profile_image_${widget.usuarioId}';

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _cargarImagenUsuario();
  }

  Future<void> _cargarDatosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString(_keyNombreUsuario);

    if (userName == null || userName.isEmpty) {
      try {
        final response = await http.get(
          Uri.parse('$urlServidor/get_user_name.php?usuario_id=${widget.usuarioId}'),
        );
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (!responseData['error']) {
            setState(() => _userName = responseData['usu_nombre']);
            await prefs.setString(_keyNombreUsuario, _userName);
          } else {
            setState(() => _userName = 'Sin usuario');
          }
        } else {
          setState(() => _userName = 'Error al cargar usuario');
        }
      } catch (e) {
        print("❌ Error al cargar el nombre de usuario: $e");
        setState(() => _userName = 'Error de conexión');
      }
    } else {
      setState(() => _userName = userName);
    }
  }

  Future<void> _cargarImagenUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedImagePath = prefs.getString(_keyProfileImage);

    if (!kIsWeb && savedImagePath != null && savedImagePath.isNotEmpty && File(savedImagePath).existsSync()) {
      setState(() {
        imgLocal = savedImagePath;
      });
    } else if (kIsWeb && savedImagePath != null && savedImagePath.isNotEmpty) {
      setState(() {
        imgLocal = savedImagePath;
      });
    } else {
      try {
        final response = await http.get(
          Uri.parse('$urlServidor/get_user_image.php?id_usu=${widget.usuarioId}'),
        );
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (!responseData['error'] && responseData['image_path'] != null) {
            final imageUrl = '$urlServidor/' + responseData['image_path'] + '?v=${DateTime.now().millisecondsSinceEpoch}';
            await prefs.setString(_keyProfileImage, imageUrl);
            setState(() {
              imgLocal = imageUrl;
            });
          }
        }
      } catch (e) {
        print("❌ Error al cargar la imagen del usuario: $e");
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? imagenSeleccionada = await _picker.pickImage(source: source);
    if (imagenSeleccionada != null) {
      bool success = await _cargarImagenAlServidor(imagenSeleccionada);
      if (success) {
        _updated = true;
        await _cargarImagenUsuario();
      }
    }
  }

  Future<bool> _cargarImagenAlServidor(XFile imageFile) async {
    try {
      var uri = Uri.parse('$urlServidor/guardar_foto.php');
      var request = http.MultipartRequest('POST', uri);
      request.fields['id_usu'] = widget.usuarioId.toString();
      String? mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      var mimeTypeSplit = mimeType.split('/');
      if (kIsWeb) {
        Uint8List imageBytes = await imageFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFile.name,
          contentType: MediaType(mimeTypeSplit[0], mimeTypeSplit[1]),
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType(mimeTypeSplit[0], mimeTypeSplit[1]),
        ));
      }
      var response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final responseJson = jsonDecode(responseBody);
      if (response.statusCode == 200 && !responseJson['error']) {
        final prefs = await SharedPreferences.getInstance();
        String urlCompleta = responseJson['image_path'];
        await prefs.setString(_keyProfileImage, urlCompleta);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("❌ Error al subir la imagen: $e");
      return false;
    }
  }

  Future<void> _deleteImage() async {
    bool confirmDelete = await _confirmDeleteDialog();
    if (!confirmDelete) return;
    try {
      var response = await http.post(
        Uri.parse('$urlServidor/eliminar_foto.php'),
        body: {'id_usu': widget.usuarioId.toString()},
      );
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyProfileImage);
        setState(() {
          imgLocal = null;
          _updated = true;
        });
      }
    } catch (e) {
      print("❌ Error al eliminar la imagen: $e");
    }
  }

  Future<bool> _confirmDeleteDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Eliminar imagen"),
              content: const Text("¿Seguro que quieres eliminar tu foto de perfil?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text("Seleccionar de galería"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (imgLocal != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Eliminar foto"),
                onTap: () {
                  Navigator.pop(context);
                  _deleteImage();
                },
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    if (imgLocal != null && imgLocal!.isNotEmpty) {
      if (imgLocal!.startsWith('http')) {
        imageProvider = NetworkImage(imgLocal!);
      } else if (!kIsWeb && File(imgLocal!).existsSync()) {
        imageProvider = FileImage(File(imgLocal!));
      } else {
        imageProvider = const AssetImage("assets/avatar.png");
      }
    } else {
      imageProvider = const AssetImage("assets/avatar.png");
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _updated);
        return false;
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFECC099),
              border: Border(bottom: BorderSide(color: Colors.black, width: 1)),
            ),
            child: AppBar(
              automaticallyImplyLeading: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                "Perfil",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              iconTheme: const IconThemeData(color: Colors.black),
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset("assets/fondo1.png", fit: BoxFit.cover),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _showImageOptions,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: imageProvider,
                      backgroundColor: Colors.grey[300],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: _showImageOptions,
                    icon: const Icon(Icons.image),
                    label: const Text("Editar imagen"),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _userName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
