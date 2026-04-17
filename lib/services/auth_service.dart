import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static Future<Map<String, dynamic>?> login(
      String username, String password) async {
    var query = await FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: username)
        .where("password", isEqualTo: password)
        .get();

    if (query.docs.isEmpty) return null;

    return query.docs.first.data();
  }
}