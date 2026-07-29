import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MaterialRequestPage extends StatelessWidget {
  const MaterialRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Store Fulfillment")),
      body: StreamBuilder<QuerySnapshot>(
        // Only show requests that are still Pending
        stream: FirebaseFirestore.instance
            .collection('material_requests')
            .where('status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return ListTile(
                title: Text("Work Order: ${doc['work_order_no']}"),
                trailing: ElevatedButton(
                  onPressed: () => _issueMaterials(doc.id),
                  child: const Text("Issue"),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _issueMaterials(String docId) async {
    // 1. Update the status to 'Issued'
    await FirebaseFirestore.instance
        .collection('material_requests')
        .doc(docId)
        .update({'status': 'Completed'});

  }
}