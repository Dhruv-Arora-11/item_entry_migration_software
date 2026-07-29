import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class PartydetailsStorage {
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> uploadDocument(
  String folder,
  String fileName,
  Uint8List bytes,
) async {

  print("uploadDocument called");

  final ref = FirebaseStorage.instance
      .ref()
      .child(folder)
      .child(fileName);

  print("Storage ref created");

  final uploadTask = ref.putData(bytes);

  print("Upload task started");

  final snapshot = await uploadTask;

  print("Upload task completed");

  final url = await snapshot.ref.getDownloadURL();

  print("URL generated");

  return url;
}

  Future<void> saveParty(String collectionName, Map<String, dynamic> data) async {
  await _firestore.collection(collectionName).add({
    ...data,
    "created_at": FieldValue.serverTimestamp(),
  });
}
}