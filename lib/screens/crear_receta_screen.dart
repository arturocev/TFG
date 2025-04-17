import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CrearRecetaScreen extends StatefulWidget {
  final Map<String, String>? receta; // Recibe una receta si se está editando

  const CrearRecetaScreen({super.key, this.receta});

  @override
  CrearRecetaScreenState createState() => CrearRecetaScreenState();
}

class CrearRecetaScreenState extends State<CrearRecetaScreen> {
  final formKey = GlobalKey<FormState>();
  late TextEditingController tituloController;
  late TextEditingController tipoController;
  late TextEditingController instruccionesController;
  late TextEditingController tiempoController;
  // Para Web usaremos imagenFile; imagenPath se usará para mostrar información
  XFile? imagenFile;
  String? imagenPath;
  bool subiendo = false;

  // Lista para almacenar los ingredientes
  List<String> ingredientes = [];
  TextEditingController ingredienteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    tituloController =
        TextEditingController(text: widget.receta?['titulo'] ?? '');
    tipoController = TextEditingController(text: widget.receta?['tipo'] ?? '');
    instruccionesController =
        TextEditingController(text: widget.receta?['instrucciones'] ?? '');
    tiempoController =
        TextEditingController(text: widget.receta?['tiempo'] ?? '');
    imagenPath = widget.receta?['imagen'];

    // Si se está editando y existen ingredientes guardados, convertir la cadena a lista
    if (widget.receta != null &&
        widget.receta?['ingredientes'] != null &&
        widget.receta!['ingredientes']!.isNotEmpty) {
      ingredientes = widget.receta!['ingredientes']!.split(', ');
    }
  }

  @override
  void dispose() {
    tituloController.dispose();
    tipoController.dispose();
    instruccionesController.dispose();
    tiempoController.dispose();
    ingredienteController.dispose();
    super.dispose();
  }

  String limpiarYValidarTexto(String texto) {
    String textoLimpio = texto.trim().replaceAll(RegExp(r'\s+'), ' ');

    if (!RegExp(r'^[a-zA-Z0-9 ]+$').hasMatch(textoLimpio)) {
      return '';
    }

    return textoLimpio;
  }
/*
  //Función para guardar el usuario
  Future<void> guardarusuario(int usuarioId) async {
    final prefs = await SharedPreferences.getInstance();
    // Suponemos que el ID se guardó con la clave 'usuarioId'
    await prefs.setInt('usuarioId', usuarioId);
  }*/

  // Función para obtener el ID del usuario almacenado en SharedPreferences
  Future<int?> obtenerUsuarioId() async {
    final prefs = await SharedPreferences.getInstance();
    // Suponemos que el ID se guardó con la clave 'usuarioId'
    return prefs.getInt('usuarioId');
  }

  Future<void> seleccionarImagen() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() {
        imagenFile = imagen;
        imagenPath = imagen.name;
      });
    }
  }

  Widget mostrarImagen() {
    if (imagenFile == null && (imagenPath == null || imagenPath!.isEmpty)) {
      return Center(
        child: Container(
          width: 150,
          height: 150,
          color: Colors.grey[300],
          child: Icon(Icons.image, color: Colors.white, size: 100),
        ),
      );
    }

    if (kIsWeb) {
      return Center(
        child: FutureBuilder<Uint8List>(
          future: imagenFile!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return Image.memory(snapshot.data!,
                  width: 150, height: 150, fit: BoxFit.cover);
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      );
    } else {
      return Center(
        child: Image.file(
          File(imagenFile!.path),
          width: 150,
          height: 150,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  Future<void> guardarReceta() async {
    if (!formKey.currentState!.validate()) return;

    if (imagenFile == null && (imagenPath == null || imagenPath!.isEmpty)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Debe seleccionar una imagen")));
      return;
    }

    if (ingredientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Debe agregar al menos un ingrediente")));
      return;
    }

    String tituloLimpio = limpiarYValidarTexto(tituloController.text);
    String tipoLimpio = limpiarYValidarTexto(tipoController.text);

    if (tituloLimpio.isEmpty || tipoLimpio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Solo se permiten letras, números y un solo espacio")),
      );
      return;
    }

    // Obtener el ID del usuario de forma dinámica
    int? usuarioId = await obtenerUsuarioId();
    if (usuarioId == null || usuarioId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: Usuario no encontrado.")),
      );
      return;
    }

    setState(() {
      subiendo = true;
    });

    var url = widget.receta == null
        ? Uri.parse("http://localhost/mandangon/guardar_receta.php")
        : Uri.parse("http://localhost/mandangon/actualizar_receta.php");

    var request = http.MultipartRequest('POST', url);

    request.fields['rec_nom'] = tituloLimpio;
    request.fields['rec_tipo_com'] = tipoLimpio;
    request.fields['rec_ing'] = ingredientes.join(', ');
    request.fields['rec_desc'] = instruccionesController.text.trim();
    request.fields['rec_tmp'] = tiempoController.text.trim();
    request.fields['rec_usu'] = usuarioId.toString();

    if (widget.receta != null) {
      request.fields['rec_nom_original'] = widget.receta!['titulo'] ?? '';
    }

    if (imagenFile != null) {
      try {
        if (kIsWeb) {
          Uint8List bytes = await imagenFile!.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'rec_img',
            bytes,
            filename: imagenFile!.name,
          ));
        } else {
          request.files
              .add(await http.MultipartFile.fromPath('imagen', imagenPath!));
        }
      } catch (e) {
        print("Error al adjuntar la imagen: $e");
      }
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    print("Respuesta del servidor: ${response.body}");

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message'] ?? 'Imagen subida correctamente')));

      Map<String, String> recetaGuardada = {
        'titulo': tituloLimpio,
        'tipo': tipoLimpio,
        'ingredientes': ingredientes.join(', '),
        'instrucciones': instruccionesController.text.trim(),
        'tiempo': tiempoController.text.trim(),
        'rec_img': imagenPath ?? '',
      };

      Navigator.pop(context, recetaGuardada);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar o actualizar la receta')));
    }

    if (!mounted) return;
    setState(() {
      subiendo = false;
    });
  }

  // Método para agregar un ingrediente a la lista
  void agregarIngrediente() {
    setState(() {
      if (ingredienteController.text.isNotEmpty) {
        ingredientes.add(ingredienteController.text);
        ingredienteController.clear();
      }
    });
  }

  // Método para eliminar un ingrediente
  void eliminarIngrediente(int index) {
    setState(() {
      ingredientes.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receta == null ? "Nueva Receta" : "Editar Receta"),
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/recetas.jpg"),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  mostrarImagen(),
                  SizedBox(height: 10),
                  Center(
                    child: ElevatedButton(
                      onPressed: seleccionarImagen,
                      child: Text("Seleccionar Imagen"),
                    ),
                  ),
                  SizedBox(height: 20),
                  campoTexto(
                    label: "Título",
                    controller: tituloController,
                    hintText: "Ejemplo: Tarta de chocolate",
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9\s]'))
                    ],
                  ),
                  SizedBox(height: 15),
                  campoTexto(
                    label: "Tipo de comida",
                    controller: tipoController,
                    hintText: "Ejemplo: Postre",
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))
                    ],
                  ),
                  SizedBox(height: 15),
                  // Campo para agregar ingredientes
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          style: TextStyle(color: Colors.white),
                          controller: ingredienteController,
                          decoration: InputDecoration(
                            labelText: "Ingrediente",
                            labelStyle: TextStyle(color: Colors.white),
                            hintText: "Ejemplo: 2 huevos",
                            hintStyle: TextStyle(color: Colors.white),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add, color: Colors.white),
                        onPressed: agregarIngrediente,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  // Lista de ingredientes
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: ingredientes.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(ingredientes[index],
                            style: TextStyle(color: Colors.white)),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.white),
                          onPressed: () => eliminarIngrediente(index),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 15),
                  campoTexto(
                    label: "Instrucciones",
                    controller: instruccionesController,
                    hintText: "Escribe los pasos de la receta...",
                    maxLines: 5,
                  ),
                  SizedBox(height: 15),
                  campoTexto(
                    label: "Tiempo estimado (minutos)",
                    controller: tiempoController,
                    hintText: "Ejemplo: 30",
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: subiendo
                        ? CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: guardarReceta,
                            child: Text(widget.receta == null
                                ? 'Guardar Receta'
                                : 'Actualizar Receta'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget campoTexto({
    required String label,
    required TextEditingController controller,
    required String hintText,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white),
        labelStyle: TextStyle(color: Colors.white),
        border: OutlineInputBorder(),
      ),
      style: TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Este campo es obligatorio";
        }
        return null;
      },
    );
  }
}
