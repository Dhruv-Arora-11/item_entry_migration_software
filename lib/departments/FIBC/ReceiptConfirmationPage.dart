import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FibcReceiptConfirmationPage extends StatefulWidget {
  const FibcReceiptConfirmationPage({super.key});

  @override
  State<FibcReceiptConfirmationPage> createState() => _FibcReceiptConfirmationPageState();
}

class _FibcReceiptConfirmationPageState extends State<FibcReceiptConfirmationPage> {
  
  Future<void> _confirmReceipt(String docId) async {
    // Update the status to 'Received'
    await FirebaseFirestore.instance.collection('material_requests').doc(docId).update({
      'status': 'Received',
      'received_at': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Material Receipt Confirmed!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FIBC Receipt Confirmation")),
      body: StreamBuilder<QuerySnapshot>(
        // Only show requests that the store has marked as 'Issued'
        stream: FirebaseFirestore.instance
            .collection('material_requests')
            .where('status', isEqualTo: 'Issued')
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
                  subtitle: const Text("Status: Pending Receipt"),
                  trailing: ElevatedButton(
                    onPressed: () => _confirmReceipt(requests[index].id),
                    child: const Text("Confirm Receive"),
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