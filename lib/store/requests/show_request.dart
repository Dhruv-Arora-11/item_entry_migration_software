import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> issueItem(DocumentSnapshot doc, BuildContext context) async {
    var data = doc.data() as Map<String, dynamic>;

    var itemQuery = await FirebaseFirestore.instance
        .collection("Items")
        .where("Item_Code", isEqualTo: data['item_code'])
        .get();

    if (itemQuery.docs.isEmpty) return;

    var itemDoc = itemQuery.docs.first;
    var itemData = itemDoc.data();

    int currentStock = itemData['Opening_Stock'] ?? 0;
    int requestedQty = data['requested_qty'];

    if (currentStock < requestedQty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Item Quantity is not enough for this request")),
      );
      return;
    }

    // 🔹 UPDATE STOCK
    await itemDoc.reference.update({
      "Opening_Stock": currentStock - requestedQty,
    });

    // 🔹 UPDATE REQUEST
    await doc.reference.update({
      "store_status": "issued",
      "issued_at": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Item Issued Successfully")),
    );
  }

class StoreRequestsScreen extends StatelessWidget {
  const StoreRequestsScreen({super.key});

  String formatDate(Timestamp? ts) {
    if (ts == null) return "N/A";
    final d = ts.toDate();
    return "${d.day}/${d.month}/${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Store Requests")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("requests")
            .where("status", isEqualTo: "approved")
            .where("store_status", isEqualTo: "pending")
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No approved requests"));
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              var doc = docs[i];
              var d = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // 🔹 ITEM NAME
                      Text(
                        d['item_name'] ?? "",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      // 🔹 DETAILS ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Qty: ${d['requested_qty']}"),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              "Pending",
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 🔹 DATES
                      Row(
                        children: [
                          Text(
                            "Due: ${formatDate(d['due_date'])}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(width: 20),
                          Text(
                            "Created: ${formatDate(d['created_at'])}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 🔹 BUTTON
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          onPressed: () async {
                            await issueItem(doc, context);
                          },
                          icon: const Icon(Icons.inventory),
                          label: const Text("Issue"),
                        ),
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

  // 🔥 ISSUE LOGIC
  
}