import 'package:app/services/party/partyDetails_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class PartyRegistrationForm extends StatefulWidget {
  final String title;
  final String collectionName;
  final List<String> fields;
  final String? existingDocId;
final Map<String, dynamic>? existingData;

  const PartyRegistrationForm({
    super.key, 
    required this.title, 
    required this.collectionName,
    required this.fields,
    this.existingData,
    this.existingDocId,
  });

  @override
  State<PartyRegistrationForm> createState() => _PartyRegistrationFormState();
}

class _PartyRegistrationFormState extends State<PartyRegistrationForm> {
  final PartydetailsStorage _service = PartydetailsStorage();
  final Map<String, TextEditingController> _ctrls = {};
  Map<String, String> docUrls = {};
  

  @override
void initState() {
  super.initState();
  for (var field in widget.fields) {
    // If existingData exists, fill the controller with it
    String initialValue = widget.existingData?[field]?.toString() ?? "";
    _ctrls[field] = TextEditingController(text: initialValue);
  }
}

  String generateVendorId() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();

  return "VND-${List.generate(
    8,
    (_) => chars[random.nextInt(chars.length)],
  ).join()}";
}
Future<void> _submit() async {
  // 1. Prepare data
  Map<String, dynamic> data = {};
  bool hasData = false;

  _ctrls.forEach((key, ctrl) {
    data[key] = ctrl.text.trim();
    if (ctrl.text.trim().isNotEmpty) {
      hasData = true;
    }
  });

  // 2. Validate
  if (!hasData) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Please fill at least one field to submit."),
      ),
    );
    return;
  }

  // 3. Save or Update
  if (widget.existingDocId == null) {
    // New Party
    data["vendorId"] = generateVendorId();
    data["createdAt"] = FieldValue.serverTimestamp();

    await _service.saveParty(widget.collectionName, data);
  } else {
    // Existing Party
    await FirebaseFirestore.instance
        .collection(widget.collectionName)
        .doc(widget.existingDocId)
        .update(data);
  }

  // 4. Success Message
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${widget.title} saved successfully!"),
      ),
    );
    Navigator.pop(context);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Register ${widget.title}")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
..._ctrls.entries.map((e) => Padding(
  padding: const EdgeInsets.only(bottom: 12),
  child: TextField(
    controller: e.value, 
    decoration: InputDecoration(
      labelText: e.key, // This will display "group" or "Group"
      border: const OutlineInputBorder(), // Professional look
      filled: true,
      fillColor: Colors.white,
    ),
  ),
)),
          ElevatedButton(onPressed: _submit, child: const Text("Submit")),
        ],
      ),
    );
  }
}