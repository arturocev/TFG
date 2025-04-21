import 'package:flutter/material.dart';
import 'package:mandangon/screens/login.dart';
import 'package:mandangon/screens/registro.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.android,
  );
  runApp(const MandangonApp());
}

class MandangonApp extends StatelessWidget {
  const MandangonApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MandangonApp',
      theme: ThemeData(
        scaffoldBackgroundColor:
            Colors.transparent, // Fondo transparente para ver la imagen
        primaryColor: Color.fromARGB(255, 145, 215, 118),
        hintColor: Color.fromARGB(255, 115, 226, 93),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
      home: const Main(title: 'Login'),
    );
  }
}

class Main extends StatefulWidget {
  const Main({super.key, required this.title});

  final String title;

  @override
  State<Main> createState() => MainEstado();
}

class MainEstado extends State<Main> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagen de fondo
          Positioned.fill(
            child: Image.asset(
              "assets/fondo1.png",
              fit: BoxFit.cover, // Ajusta la imagen al tamaño de la pantalla
            ),
          ),
          // Contenido principal
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo Mandangon
                Padding(
                  padding: const EdgeInsets.only(bottom: 0),
                  child: const Image(
                    image: AssetImage("assets/logo.png"),
                    width: 300.0, // Ancho deseado
                    height: 150.0, // Alto deseado
                  ),
                ),
                // Botón de Iniciar Sesión
                Padding(
                  padding: const EdgeInsets.only(bottom: 30),
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => IniciarSesion()),
                      );
                    },
                    label: const Text(
                      "Iniciar sesión",
                      style: TextStyle(
                        color: Color.fromARGB(255, 10, 56, 1),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: const Color.fromARGB(255, 36, 230, 43),
                    heroTag: "btn1",
                  ),
                ),
                // Botón de Registro
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Registro()),
                      );
                    },
                    label: const Text(
                      "Registrarse",
                      style: TextStyle(
                        color: Color.fromARGB(255, 18, 1, 66),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: const Color.fromARGB(255, 80, 255, 220),
                    heroTag: "btn2",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
