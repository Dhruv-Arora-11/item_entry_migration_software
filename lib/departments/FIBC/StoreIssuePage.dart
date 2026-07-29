import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreIssuePage extends StatefulWidget {
  const StoreIssuePage({super.key});

  @override
  State<StoreIssuePage> createState() => _StoreIssuePageState();
}

class _StoreIssuePageState extends State<StoreIssuePage> {
  
  Future<void> _issueMaterial(String docId) async {
    // Update the status to 'Issued' in Firestore
    await FirebaseFirestore.instance.collection('material_requests').doc(docId).update({
      'status': 'Issued',
      'issued_at': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Material Issued Successfully!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Store Issue Dashboard")),
      body: StreamBuilder<QuerySnapshot>(
        // Only show requests that are still 'Pending'
        stream: FirebaseFirestore.instance
            .collection('material_requests')
            .where('status', isEqualTo: 'Pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final requests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final data = requests[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("Work Order: ${data['work_order_no']}"),
                  subtitle: Text("Status: ${data['status']}"),
                  trailing: ElevatedButton(
                    onPressed: () => _issueMaterial(requests[index].id),
                    child: const Text("Issue"),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}