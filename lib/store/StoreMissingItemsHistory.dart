import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StoreMissingReportHistory extends StatelessWidget {
  const StoreMissingReportHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Missing Item Reports")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Missing_Items_Reports")
            .where("reported_by", isEqualTo: "Store Manager")
            .orderBy("created_at", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (ctx, i) {
              var data = snapshot.data!.docs[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(data['item_name']),
                  subtitle: Text("Status: ${data['status']} | Date: ${data['created_at'].toDate().toString().substring(0, 10)}"),
                  leading: Icon(
                    data['status'] == 'Resolved' ? Icons.check_circle : Icons.pending,
                    color: data['status'] == 'Resolved' ? Colors.green : Colors.orange,
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