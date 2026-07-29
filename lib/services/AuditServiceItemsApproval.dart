import 'package:cloud_firestore/cloud_firestore.dart';

class AuditService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> logAction({
    required String referenceId, // e.g., GE-123 or GR-123
    required String action,      // e.g., "Gate Entry Created", "Approved by Dept"
    required String performedBy, // e.g., "Civil Dept Head"
    String details = "",
  }) async {
    await _firestore.collection("Process_History").add({
      "reference_id": referenceId,
      "action": action,
      "performed_by": performedBy,
      "details": details,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }
}