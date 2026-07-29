import 'package:cloud_firestore/cloud_firestore.dart';

class StoreReceiptService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> generateGR({
    required String grNo,
    required String gateEntryNo,
    required Map<String, dynamic> gateData,
    required List<Map<String, dynamic>> verifiedItems,
  }) async {
    final batch = _firestore.batch();
    String department = gateData['department'];

    // Create Store Receipt
    final receiptRef = _firestore.collection("Store_Receipts").doc(grNo);

    batch.set(receiptRef, {
      "gr_no": grNo,
      "gate_entry_no": gateEntryNo,
      "bill_no": gateData['bill_no'],
      "challan_no": gateData['challan_no'],
      "party": gateData['party'],
      "date": FieldValue.serverTimestamp(),
      "status": "Pending Department Approval",
    });

    double totalAmountForAccounts = 0;

    // Process Items
    for (var item in verifiedItems) {
      String status = item['status'] ?? 'Confirmed';

      // Save Verified Items
      batch.set(
        receiptRef.collection("Verified_Items").doc(),
        {
          "item_description": item['item_description'],
          "status": status,
          "bill_qty": item['bill_qty'],
        },
      );

      // Calculate estimated amount only
      if (status == 'Confirmed' &&
          item['item_code'] != null &&
          item['item_code'].toString().isNotEmpty) {
        final itemSnap = await _firestore
            .collection("Items")
            .where("Item_Code", isEqualTo: item['item_code'])
            .limit(1)
            .get();

        if (itemSnap.docs.isNotEmpty) {
          double price =
              (itemSnap.docs.first.data()['Amount'] ?? 0).toDouble();

          totalAmountForAccounts +=
              price * (item['bill_qty'] as num).toDouble();
        }
      }

      // Missing Item Report
      if (status == 'Missing Item') {
        batch.set(
          _firestore.collection("Missing_Items_Reports").doc(),
          {
            "gate_entry_no": gateEntryNo,
            "item_name": item['item_description'],
            "reported_by": "Store Manager",
            "created_at": FieldValue.serverTimestamp(),
          },
        );
      }
    }

    // Update Gate Entry Status
    batch.update(
      _firestore.collection("Gate_Entries").doc(gateEntryNo),
      {
        "status": "Verified by Store",
      },
    );

    // Create Approval Memo
    String memoNo =
        "AM-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

    batch.set(
      _firestore.collection("Approval_Memos").doc(memoNo),
      {
        "memo_no": memoNo,
        "gr_no": grNo,
        "gate_entry_no": gateEntryNo,
        "bill_no": gateData['bill_no'],
        "party": gateData['party'],
        "department": department,
        "total_amount_estimated": totalAmountForAccounts,
        "status": "Pending Approval",
        "date": FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }
}