import 'package:cloud_firestore/cloud_firestore.dart';

class EntryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> fetchEntries() {
    return _firestore
        .collection("Gate_Entries")
        .orderBy("approved_at", descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> fetchEntryItems(String entryId) {
    return _firestore
        .collection("Gate_Entries")
        .doc(entryId)
        .collection("Items")
        .snapshots();
  }
}