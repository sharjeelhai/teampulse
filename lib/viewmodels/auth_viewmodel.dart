import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teampulse/repositories/user_repository.dart';
import 'package:teampulse/services/local_storage_service.dart';
import '../models/user_model.dart';
import '../utils/extensions.dart';

class AuthViewModel extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  // -------------------------
  // Sign up
  // -------------------------
  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? chapterId,
    String? teamId,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    debugPrint('Starting signup for: $email');

    try {
      // 1) Create Firebase Auth user
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create auth user');
      }

      final String uid = firebaseUser.uid;
      debugPrint('Auth user created uid=$uid');

      // 2) Prepare Firestore payload (use server timestamp)
      final Map<String, dynamic> userPayload = {
        'id': uid,
        'name': name,
        'email': email,
        'role': role.toString().split('.').last,
        'chapterId': chapterId,
        'teamId': teamId,
        'avatarInitials': name.getInitials(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      debugPrint('Writing user doc to Firestore for uid=$uid');

      // 3) Write user doc (doc id == auth uid)
      await _firestore.collection('users').doc(uid).set(userPayload);

      // 4) Read back the document to obtain serverTimestamp as Timestamp
      final DocumentSnapshot<Map<String, dynamic>> doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) {
        throw Exception('User document missing after creation');
      }

      final user = UserModel.fromMap(doc.data()!, doc.id);

      // 5) Save a serializable local copy
      try {
        await LocalStorageService.saveUser(user.toMap());
      } catch (localErr) {
        debugPrint('Warning: failed to save user locally: $localErr');
        // Not critical for signup success
      }

      _currentUser = user;
      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e, st) {
      debugPrint(
        'FirebaseAuthException during signup: code=${e.code} message=${e.message}\n$st',
      );
      _errorMessage = _getAuthErrorMessage(e.code);
      _setLoading(false);
      notifyListeners();
      return false;
    } on FirebaseException catch (e, st) {
      debugPrint(
        'FirebaseException during signup: code=${e.code} message=${e.message}\n$st',
      );

      // Try to cleanup: delete the created auth user so there are no orphan accounts
      try {
        final current = _auth.currentUser;
        if (current != null) {
          await current.delete();
          debugPrint(
            'Deleted auth user after Firestore failure (uid=${current.uid})',
          );
        }
      } catch (deleteErr) {
        debugPrint(
          'Failed to delete auth user after Firestore failure: $deleteErr',
        );
      }

      _errorMessage = e.message ?? 'Failed to save profile. Please try again.';
      _setLoading(false);
      notifyListeners();
      return false;
    } catch (e, st) {
      debugPrint('Unexpected error during signup: $e\n$st');

      try {
        // Attempt sign out / cleanup
        await _auth.signOut();
      } catch (_) {}

      _errorMessage = 'An unexpected error occurred. Please try again.';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // -------------------------
  // Sign in
  // -------------------------
  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('Attempting to sign in with email: $email');
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to sign in');
      }

      debugPrint(
        'Firebase Auth sign in successful for uid=${firebaseUser.uid}',
      );

      // Fetch user profile from Firestore
      UserModel? user = await _userRepository.getUserById(firebaseUser.uid);

      if (user == null) {
        // If profile missing, attempt to create a minimal profile (default role = member)
        debugPrint(
          'Firestore profile missing for uid=${firebaseUser.uid}, creating basic profile',
        );

        final basicUser = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'Unknown User',
          email: firebaseUser.email ?? '',
          role: UserRole.member,
          avatarInitials: (firebaseUser.displayName ?? 'U').getInitials(),
          chapterId: null,
          teamId: null,
          createdAt: DateTime.now(),
        );

        try {
          await _userRepository.createUser(basicUser);
          user = basicUser;
          debugPrint('Basic profile created for uid=${firebaseUser.uid}');
        } catch (createErr) {
          debugPrint('Failed to create basic profile: $createErr');
          // Sign out to keep consistent state
          await _auth.signOut();
          _errorMessage =
              'Account exists but profile creation failed. Please contact support.';
          _setLoading(false);
          notifyListeners();
          return false;
        }
      }

      // Validate user data minimally
      if (user.name.isEmpty || user.email.isEmpty) {
        debugPrint('User profile incomplete for uid=${user.id}');
        _errorMessage = 'User profile is incomplete. Please contact support.';
        await _auth.signOut();
        _setLoading(false);
        notifyListeners();
        return false;
      }

      // Save locally
      try {
        await LocalStorageService.saveUser(user.toMap());
      } catch (localErr) {
        debugPrint('Warning: failed to save user locally: $localErr');
      }

      _currentUser = user;
      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e, st) {
      debugPrint(
        'FirebaseAuthException during signIn: code=${e.code} message=${e.message}\n$st',
      );
      _errorMessage = _getAuthErrorMessage(e.code);
      _setLoading(false);
      notifyListeners();
      return false;
    } catch (e, st) {
      debugPrint('Unexpected error during signIn: $e\n$st');
      _errorMessage = 'An error occurred. Please try again.';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // -------------------------
  // Sign out
  // -------------------------
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out from FirebaseAuth: $e');
    }

    try {
      await LocalStorageService.deleteUser();
    } catch (e) {
      debugPrint('Error deleting local user data: $e');
    }

    _currentUser = null;
    notifyListeners();
  }

  // -------------------------
  // Load user from local storage (and refresh from Firestore if possible)
  // -------------------------
  Future<void> loadUserFromLocal() async {
    try {
      final userData = LocalStorageService.getUser();
      if (userData != null) {
        // Expect a Map<String, dynamic>
        final map = Map<String, dynamic>.from(userData);
        final id = map['id'] ?? map['uid'] ?? map['userId'];
        if (id == null) {
          debugPrint('Local user data missing id');
          return;
        }

        _currentUser = UserModel.fromMap(map, id as String);

        // Try to refresh from Firestore
        final fresh = await _userRepository.getUserById(_currentUser!.id);
        if (fresh != null) {
          _currentUser = fresh;
          try {
            await LocalStorageService.saveUser(fresh.toMap());
          } catch (e) {
            debugPrint(
              'Warning: failed to update local storage with fresh user: $e',
            );
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user from local: $e');
    }
  }

  // -------------------------
  // Update user profile
  // -------------------------
  Future<bool> updateProfile({
    String? name,
    UserRole? role,
    String? chapterId,
    String? teamId,
  }) async {
    if (_currentUser == null) return false;

    try {
      _setLoading(true);

      final updates = <String, dynamic>{};
      if (name != null) {
        updates['name'] = name;
        updates['avatarInitials'] = name.getInitials();
      }
      if (role != null) updates['role'] = role.toString().split('.').last;
      if (chapterId != null) updates['chapterId'] = chapterId;
      if (teamId != null) updates['teamId'] = teamId;

      await _userRepository.updateUser(_currentUser!.id, updates);

      _currentUser = _currentUser!.copyWith(
        name: name,
        role: role,
        chapterId: chapterId,
        teamId: teamId,
        avatarInitials: name?.getInitials(),
      );

      try {
        await LocalStorageService.saveUser(_currentUser!.toMap());
      } catch (e) {
        debugPrint('Warning: failed to persist updated user locally: $e');
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to update profile: $e');
      _errorMessage = 'Failed to update profile';
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // -------------------------
  // Helper
  // -------------------------
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
