import 'package:firebase_auth/firebase_auth.dart';

class AuthRoleService {
  const AuthRoleService();

  Stream<bool> watchIsAdmin() {
    return FirebaseAuth.instance.idTokenChanges().asyncMap((user) async {
      return isAdmin(user);
    });
  }

  Future<bool> isAdmin([User? user]) async {
    final target = user ?? FirebaseAuth.instance.currentUser;
    if (target == null) {
      return false;
    }
    try {
      final token = await target.getIdTokenResult(true);
      final role = token.claims?['role']?.toString().toLowerCase();
      return role == 'admin';
    } catch (_) {
      return false;
    }
  }
}
