import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthUser {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '801044998395-p1tofgc96lki4p3qpn8ijbs85f9lt4j1.apps.googleusercontent.com',
  );

  Future<User?> loginGoogle() async {
    final googleAccount = await _googleSignIn.signIn();
    final googleAuth = await googleAccount?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    return userCredential.user;
  }

  Future<void> cerrarSesion() async {
    try {
      await _googleSignIn.signOut(); // Usar la MISMA instancia
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }
}
