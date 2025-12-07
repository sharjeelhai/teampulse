import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auth instance
  static FirebaseAuth get auth => _auth;

  // Firestore instance
  static FirebaseFirestore get firestore => _firestore;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  static bool get isSignedIn => _auth.currentUser != null;

  // Sign in with email and password
  static Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password
  static Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password reset
  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Get collection reference
  static CollectionReference collection(String collectionName) {
    return _firestore.collection(collectionName);
  }

  // Get document reference
  static DocumentReference doc(String collectionName, String docId) {
    return _firestore.collection(collectionName).doc(docId);
  }
}
