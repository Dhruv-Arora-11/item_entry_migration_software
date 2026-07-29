import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestPanelScreen extends StatelessWidget {
  const RequestPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Requests Panel")),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: "Pending"),
                Tab(text: "Approved"),
                Tab(text: "Rejected"),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildList("pending", Colors.orange, true),
                  _buildList("approved", Colors.green, false),
                  _buildList("rejected", Colors.red, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(String status, Color color, bool actions) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("requests")
          .where("status", isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        // 🔹 LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 🔹 ERROR
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading requests"));
        }

        // 🔹 EMPTY
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No requests found"));
        }

        var docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
  var doc = docs[i];
  var d = doc.data() as Map<String, dynamic>;

  List<dynamic> items = d['items'] ?? [];

  String title = "No Items";
  DateTime? minDate;
  int totalQty = 0;

  if (items.isNotEmpty) {
    title = items.first['item_name'] ?? "Unknown Item";

    if (items.length > 1) {
      title += " + ${items.length - 1} more";
    }

    for (var item in items) {
      totalQty +=
          int.tryParse(item['requested_qty'].toString()) ?? 0;

      if (item['due_date'] != null) {
        DateTime dt =
            (item['due_date'] as Timestamp).toDate();

        if (minDate == null || dt.isBefore(minDate)) {
          minDate = dt;
        }
      }
    }
  }

  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(vertical: 6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
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
                    subtitle: Text(
                      "Qty: ${item['requested_qty']}",
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              minDate != null
                  ? "Due: ${minDate.day}-${minDate.month}-${minDate.year}"
                  : "No Due Date",
            ),

            const SizedBox(height: 6),

            Text("Qty: $totalQty"),
            Text("Dept: ${d['department']}"),

            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (actions)
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.green,
                    ),
                    onPressed: () {
                      doc.reference.update({
                        "status": "approved",
                        "approved_by":
                            "super_admin",
                        "approved_at":
                            FieldValue
                                .serverTimestamp(),
                        "store_status":
                            "pending",
                      });
                    },
                    icon: const Icon(Icons.check),
                    label:
                        const Text("Approve"),
                  ),

                  const SizedBox(width: 10),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red,
                    ),
                    onPressed: () {
                      doc.reference.update({
                        "status": "rejected",
                        "rejected_by":
                            "super_admin",
                        "rejected_at":
                            FieldValue
                                .serverTimestamp(),
                      });
                    },
                    icon: const Icon(Icons.close),
                    label:
                        const Text("Reject"),
                  ),
                ],
              ),
          ],
        ),
      ),
    ),
  );
}
        );
      },
    );
  }
}
