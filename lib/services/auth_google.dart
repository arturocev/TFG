import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthUser {
  Future loginGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: '801044998395-p1tofgc96lki4p3qpn8ijbs85f9lt4j1.apps.googleusercontent.com',
    );

    final googleAccount = await googleSignIn.signIn();
    final googleAuth = await googleAccount?.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    return userCredential.user;
  }
}