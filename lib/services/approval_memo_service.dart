import 'package:cloud_firestore/cloud_firestore.dart';

class ApprovalMemoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> fetchPendingMemos(String department) {
    print("DEBUG: Querying Dept: '${department.trim()}'");
    return _firestore
        .collection("Approval_Memos")
        .where("department", isEqualTo: department)
        .where("status", isEqualTo: "Pending Approval")
        .snapshots();
  }

  Future<void> approveMemo(String memoId, Map<String, dynamic> memoData) async {
    final batch = _firestore.batch();

    String grNo = memoData['gr_no'];
    double totalBillAmount = 0;

    // Fetch verified items
    var itemsSnap = await _firestore
        .collection("Store_Receipts")
        .doc(grNo)
        .collection("Verified_Items")
        .get();


    for (var doc in itemsSnap.docs) {
      var itemData = doc.data();

      var itemMaster = await _firestore
          .collection("Items")
          .where(
            "Item_Name",
            isEqualTo: itemData['item_description'],
          )
          .limit(1)
          .get();

      double price = 0;

      if (itemMaster.docs.isNotEmpty) {
        var itemDoc = itemMaster.docs.first;

        price =
            (itemDoc.data()['Amount'] ?? 0).toDouble();

        double currentStock =
            (itemDoc.data()['Opening_Stock'] ?? 0)
                .toDouble();

        double qty = double.tryParse(
                itemData['bill_qty'].toString()) ??
            0;

        // Update Stock
        batch.update(itemDoc.reference, {
          "Opening_Stock": currentStock + qty,
        });

      }

      double qty =
          double.tryParse(itemData['bill_qty'].toString()) ??
              0;


      totalBillAmount += price * qty;
    }


    // Update Approval Memo
    batch.update(
      _firestore.collection("Approval_Memos").doc(memoId),
      {
        "status": "Approved",
        "approved_at": FieldValue.serverTimestamp(),
      },
    );


    // Update Gate Entry
    batch.update(
  _firestore
      .collection("Gate_Entries")
      .doc(memoData['gate_entry_no']),
  {
    "status": "Approved by Dept",
    "total_amount": totalBillAmount,
    "approved_at": FieldValue.serverTimestamp(),
    "payment_status": "Pending",
  },
);


    await batch.commit();

  }
}