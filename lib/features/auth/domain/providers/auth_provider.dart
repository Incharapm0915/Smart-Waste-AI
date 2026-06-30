import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

final authProvider = StateNotifierProvider<AuthNotifier, User?>(
  (ref) => AuthNotifier(),
);

final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthNotifier extends StateNotifier<User?> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();

  AuthNotifier() : super(FirebaseAuth.instance.currentUser);

  Future<void> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    state = credential.user;
  }

  Future<void> signInWithGoogle() async {
    late UserCredential userCredential;

    if (kIsWeb) {
      // Redirect flow: page navigates to Google and comes back.
      // getRedirectResult() is handled in main.dart on the return load.
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.addScope('profile');
      await _auth.signInWithRedirect(provider);
      return; // page will reload; main.dart handles the result
    } else {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // user cancelled
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      userCredential = await _auth.signInWithCredential(credential);
    }

    final user = userCredential.user!;

    // Create Firestore doc only for new users
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'sustainabilityScore': 0,
        'totalItemsSaved': 0,
        'wasteReduced': 0.0,
      });
    }

    state = user;
  }

  Future<void> signUp(String email, String password, String name) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await credential.user?.updateDisplayName(name);
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'uid': credential.user!.uid,
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'sustainabilityScore': 0,
      'totalItemsSaved': 0,
      'wasteReduced': 0.0,
    });
    state = credential.user;
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try { await _googleSignIn.signOut(); } catch (_) {}
    }
    await _auth.signOut();
    state = null;
  }
}
