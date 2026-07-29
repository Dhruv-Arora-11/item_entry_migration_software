import 'package:cloud_firestore/cloud_firestore.dart';

class GateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create Gate Entry
  Future<void> createGateEntry({
    required String gateEntryNo,
    required String billNo,
    required String challanNo,
    required String party,
    required String vehicleNo,
    required String? department, // 🔥 NEW: Crucial for routing later
    required List<Map<String, dynamic>> items,
  }) async {
    final gateRef = _firestore.collection("Gate_Entries").doc(gateEntryNo);
    
    final batch = _firestore.batch();
    
    // Save the main entry details
    batch.set(gateRef, {
      "gate_entry_no": gateEntryNo,
      "bill_no": billNo,
      "challan_no": challanNo,
      "party": party,
      "vehicle_no": vehicleNo,
      "department": department, // 🔥 Saved here
      "date": FieldValue.serverTimestamp(),
      "status": "Pending Store Receipt",
    });

    // Save the items in a subcollection
    for (var item in items) {
      final itemRef = gateRef.collection("Items").doc();
      batch.set(itemRef, {
        "item_description": item['item_description'],
        "qty": item['qty'],
        "weight": item['weight'],
      });
    }

    await batch.commit();
  }

  // 🔥 Fetch departments for the dropdown
  Stream<QuerySnapshot> fetchDepartments() {
    return _firestore.collection("departments").snapshots();
  }

  Stream<QuerySnapshot> fetchPendingGateEntries() {
    return _firestore
        .collection("Gate_Entries")
        .where("status", isEqualTo: "Pending Store Receipt")
        .snapshots();
  }
}