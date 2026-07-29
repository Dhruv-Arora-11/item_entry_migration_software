import 'package:cloud_firestore/cloud_firestore.dart';

class MissingItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> reportMissingItems({
    required String gateEntryNo,
    required List<Map<String, dynamic>> items,
    required String reason,
  }) async {
    final batch = _firestore.batch();
    
    for (var item in items) {
      final reportRef = _firestore.collection("Missing_Items_Reports").doc();
      batch.set(reportRef, {
        "gate_entry_no": gateEntryNo,
        "item_name": item['item_description'],
        "item_code": item['item_code'],
        "reported_by": "Store Manager",
        "reason": reason,
        "created_at": FieldValue.serverTimestamp(),
        "status": "Pending"
      });
    }
    await batch.commit();
  }
  Future<void> resolveMissingItem(String reportId) async {
    await _firestore.collection("Missing_Items_Reports").doc(reportId).update({
      "status": "Resolved",
      "resolved_at": FieldValue.serverTimestamp(),
    });
  }
}