import 'package:cloud_firestore/cloud_firestore.dart';

class ItemService {
  final _db = FirebaseFirestore.instance;

  bool canEdit(Map item, bool isAdmin) {
  if (isAdmin) return true;

  DateTime? createdAt = item['Create_at']?.toDate();
  bool unlocked = item['edit_unlocked'] == true;

  if (createdAt == null) return false;

  if (DateTime.now().difference(createdAt).inHours < 48) {
    return true;
  }

  return unlocked;
}

  Future<void> updateItem({
    required String docId,
    required Map<String, dynamic> oldData,
    required Map<String, dynamic> newData,
  }) async {
    Map<String, dynamic> changes = {};

    newData.forEach((key, value) {
      if (oldData[key] != value) {
        changes[key] = {
          "old": oldData[key],
          "new": value,
        };
      }
    });

    //UPDATE ITEM
    await _db.collection("Items").doc(docId).update(newData);

    //SAVE LOG
    await _db.collection("item_logs").add({
      "item_id": docId,
      "item_code": oldData['Item_Code'],
      "edited_by": oldData['User_Name'] ?? "unknown",
      "edited_at": FieldValue.serverTimestamp(),
      "changes": changes,
    });
  }

  //STREAM LOGS
  Stream<QuerySnapshot> getLogs(String itemId) {
    return _db
        .collection("item_logs")
        .where("item_id", isEqualTo: itemId)
        .orderBy("edited_at", descending: true)
        .snapshots();
  }

  //DELETE LOGS (LAST N DAYS)
  Future<void> deleteLogsLastNDays(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));

    final snapshot = await _db
        .collection("item_logs")
        .where("edited_at", isLessThan: cutoff)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  //UNLOCK ITEM (ADMIN)
  Future<void> unlockItem(String docId) async {
    await _db.collection("Items").doc(docId).update({
      "edit_locked": false
    });
  }
}