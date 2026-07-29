import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HRRejectedScreen extends StatelessWidget {
  final String departmentName;
  const HRRejectedScreen({super.key,required this.departmentName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rejected Requests")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection("requests")
            .where("department", isEqualTo: departmentName)
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
    var d = docs[i].data() as Map<String, dynamic>;

    List<dynamic> items = d['items'] ?? [];

    String title = "No Items";

    if (items.isNotEmpty) {
      title = items.first['item_name'] ?? "Unknown Item";

      if (items.length > 1) {
        title += " + ${items.length - 1} more";
      }
    }

    int totalQty = 0;

    for (var item in items) {
      totalQty +=
          int.tryParse(item['requested_qty'].toString()) ?? 0;
    }

    return Card(
      color: Colors.red.shade50,
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Rejected Order"),
              content: SizedBox(
                width: 500,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final item = items[index];

                    return ListTile(
                      title: Text(
                        item['item_name'] ?? '',
                      ),
                      trailing: Text(
                        "Qty: ${item['requested_qty']}",
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
        child: ListTile(
          title: Text(title),
          subtitle: Text(
            "Total Qty: $totalQty\nDept: ${d['department']}",
          ),
          trailing: const Icon(
            Icons.cancel,
            color: Colors.red,
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