import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HRRejectedScreen extends StatelessWidget {
  const HRRejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rejected Requests")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("requests")
            .where("department", isEqualTo: "HR")
            .where("status", isEqualTo: "rejected")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: const CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
  itemCount: docs.length,
  itemBuilder: (context, i) {
    var d = docs[i];

    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(d['item_name']),
        subtitle: Text("Qty: ${d['requested_qty']}"),
        trailing: const Icon(Icons.cancel, color: Colors.red),
      ),
    );
  },
);
        },
      ),
    );
  }
}