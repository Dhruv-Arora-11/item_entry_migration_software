import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HRRequestsScreen extends StatelessWidget {
  final String departmentName;
  
  const HRRequestsScreen({
    super.key,
    required this.departmentName
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Requests")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("requests")
            .where("department", isEqualTo: departmentName)
            .where("status", whereIn: ["pending", "approved"]).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: const CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          Color getColor(String status) {
            switch (status) {
              case "approved":
                return Colors.green;
              case "pending":
                return Colors.orange;
              default:
                return Colors.grey;
            }
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var d = docs[i];

              return Center(
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    title: Text(d['item_name']),
                    subtitle: Text("Qty: ${d['requested_qty']}"),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: getColor(d['status']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        d['status'],
                        style: TextStyle(
                          color: getColor(d['status']),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
