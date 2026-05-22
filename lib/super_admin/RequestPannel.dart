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

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 ITEM NAME
                    Text(
                      d['item_name'] ?? "",
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      d['due_date'] != null
                          ? "Due: ${d['due_date'].toDate().day}-${d['due_date'].toDate().month}-${d['due_date'].toDate().year}"
                          : "No Due Date",
                    ),
                    const SizedBox(height: 6),

                    // 🔹 DETAILS
                    Text("Qty: ${d['requested_qty']}"),
                    Text("Dept: ${d['department']}"),

                    const SizedBox(height: 6),

                    // 🔹 STATUS TAG
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.bold),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 🔹 ACTIONS
                    if (actions)
                      Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green),
                            onPressed: () {
                              doc.reference.update({
                                "status": "approved",
                                "approved_by": "super_admin",
                                "approved_at": FieldValue.serverTimestamp(),
                                "store_status": "pending",
                              });
                            },
                            icon: const Icon(Icons.check),
                            label: const Text("Approve"),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            onPressed: () {
                              doc.reference.update({
                                "status": "rejected",
                                "rejected_by": "super_admin",
                                "rejected_at": FieldValue.serverTimestamp(),
                              });
                            },
                            icon: const Icon(Icons.close),
                            label: const Text("Reject"),
                          ),
                        ],
                      )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
