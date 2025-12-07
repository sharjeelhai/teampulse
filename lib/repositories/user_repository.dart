import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teampulse/services/firebase_service.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class UserRepository {
  final CollectionReference _usersCollection = FirebaseService.collection(
    AppConstants.usersCollection,
  );

  // Create user
  Future<void> createUser(UserModel user) async {
    await _usersCollection.doc(user.id).set(user.toMap());
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Get user stream
  Stream<UserModel?> getUserStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  // Update user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _usersCollection.doc(userId).update(data);
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    await _usersCollection.doc(userId).delete();
  }

  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _usersCollection.get();
    return snapshot.docs
        .map(
          (doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // Get users by role
  Future<List<UserModel>> getUsersByRole(UserRole role) async {
    final snapshot = await _usersCollection
        .where('role', isEqualTo: role.toString().split('.').last)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // Get users by chapter
  Future<List<UserModel>> getUsersByChapter(String chapterId) async {
    final snapshot = await _usersCollection
        .where('chapterId', isEqualTo: chapterId)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // Get users by team
  Future<List<UserModel>> getUsersByTeam(String teamId) async {
    final snapshot = await _usersCollection
        .where('teamId', isEqualTo: teamId)
        .get();
    return snapshot.docs
        .map(
          (doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  // Search users by name
  Future<List<UserModel>> searchUsersByName(String query) async {
    final snapshot = await _usersCollection.get();
    return snapshot.docs
        .map(
          (doc) =>
              UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .where((user) => user.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get user by email (workaround: get all users and filter)
  Future<UserModel?> getUserByEmail(String email) async {
    final allUsers = await getAllUsers();
    try {
      return allUsers.firstWhere(
        (user) => user.email.trim().toLowerCase() == email.trim().toLowerCase(),
      );
    } catch (e) {
      // No user found with this email
      return null;
    }
  }
}
