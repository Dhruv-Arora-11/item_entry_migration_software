import 'package:app/store/Item_related_services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ItemLogsScreen extends StatelessWidget {
  final String itemId;

  const ItemLogsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context) {
    final service = ItemService();

    return Scaffold(
      appBar: AppBar(title: const Text("Edit History")),
      body: StreamBuilder<QuerySnapshot>(
        stream: service.getLogs(itemId),
        builder: (context, snapshot) {
          // 🔹 LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 🔹 ERROR (IMPORTANT)
          if (snapshot.hasError) {
            print("LOG ERROR: ${snapshot.error}");

            return const Center(
              child: Text(
                "⚠️ Index required or error occurred",
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          // 🔹 NO DATA
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No edit history found",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          var logs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              var log = logs[index].data() as Map<String, dynamic>;

              var changes = (log['changes'] as Map<String, dynamic>?) ?? {};

              return Container(
  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade200),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 8,
        offset: const Offset(0, 3),
      )
    ],
  ),
  child: Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // 🔹 HEADER (clean + aligned)
        Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.person, size: 14, color: Colors.blue),
            ),
            const SizedBox(width: 8),

            Expanded(
              child: Text(
                log['edited_by'] ?? "Unknown",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            Text(
              log['edited_at'] != null
                  ? (log['edited_at'] as Timestamp)
                      .toDate()
                      .toString()
                      .substring(0, 16)
                  : "",
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // 🔥 TABLE HEADER
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: const [
              Expanded(flex: 3, child: Text("Field", style: TextStyle(fontWeight: FontWeight.w600))),
              Expanded(flex: 3, child: Text("Old", style: TextStyle(fontWeight: FontWeight.w600))),
              Expanded(flex: 3, child: Text("New", style: TextStyle(fontWeight: FontWeight.w600))),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // 🔥 CHANGES
        Column(
          children: changes.entries.map((e) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [

                  // Field
                  Expanded(
                    flex: 3,
                    child: Text(
                      e.key.replaceAll("_", " "),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

                  // Old
                  Expanded(
                    flex: 3,
                    child: Text(
                      e.value['old']?.toString() ?? "null",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),

                  // New
                  Expanded(
                    flex: 3,
                    child: Text(
                      e.value['new']?.toString() ?? "null",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
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
