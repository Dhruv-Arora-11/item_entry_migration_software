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
              var data = d.data() as Map<String, dynamic>;
List<dynamic> items = data['items'] ?? [];

return Center(
  child: Card(
    margin: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
    child: InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Requested Items"),
            content: SizedBox(
              width: 500,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final item = items[index];

                  return ListTile(
                    title: Text(
                      item['item_name'] ?? 'Unknown Item',
                    ),
                    subtitle: Text(
                      "Code: ${item['item_code'] ?? 'N/A'}",
                    ),
                    trailing: Text(
                      "Qty: ${item['requested_qty']}",
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
      child: ListTile(
        title: Text(
          "${items.length} Items Requested",
        ),
        subtitle: Text(
          "Department: ${data['department']}",
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: getColor(data['status'])
                .withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            data['status'],
            style: TextStyle(
              color: getColor(data['status']),
              fontWeight: FontWeight.w600,
            ),
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
