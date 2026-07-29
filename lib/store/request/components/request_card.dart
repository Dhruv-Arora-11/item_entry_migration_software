import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestCard extends StatelessWidget {
  final DocumentSnapshot doc;
  final bool pending;

  const RequestCard({
    super.key,
    required this.doc,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    var data = doc.data() as Map<String, dynamic>;
    List<dynamic> items = data['items'] ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showOrderDetails(context, data),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              ListTile(
                title: Text(
                  "Department: ${data['department'] ?? 'N/A'}",
                ),
                subtitle: Text(
                  "Status: ${data['store_status'] ?? 'Pending'}",
                ),
                trailing: Text(
                  "${items.length} Items",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Divider(),

              ...items.take(3).map(
                (item) => ListTile(
                  dense: true,
                  title: Text(
                    item['item_name'] ?? 'Unknown Item',
                  ),
                  trailing: Text(
                    "Qty: ${item['requested_qty']}",
                  ),
                ),
              ),

              if (items.length > 3)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    "+ ${items.length - 3} more items",
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              if (pending)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _handleIssue(context, doc),
                    icon: const Icon(Icons.inventory_2),
                    label: const Text("Issue Order"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetails(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    List<dynamic> items = data['items'] ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Order Items (${items.length})",
        ),
        content: SizedBox(
          width: 500,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                child: ListTile(
                  title: Text(
                    item['item_name'] ?? 'Unknown Item',
                  ),
                  subtitle: Text(
                    "Code: ${item['item_code'] ?? 'N/A'}",
                  ),
                  trailing: Text(
                    "Qty: ${item['requested_qty']}",
                  ),
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
  }

  Future<void> _handleIssue(
    BuildContext context,
    DocumentSnapshot orderDoc,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;

      var data = orderDoc.data() as Map<String, dynamic>;
      List<dynamic> items = data['items'] ?? [];

      var batch = firestore.batch();

      for (var item in items) {
        String itemCode = item['item_code'] ?? '';

        int requestQty =
            int.tryParse(item['requested_qty'].toString()) ?? 0;

        var itemQuery = await firestore
            .collection("Items")
            .where("Item_Code", isEqualTo: itemCode)
            .get();

        if (itemQuery.docs.isEmpty) {
          throw "Item ${item['item_name']} not found";
        }

        var itemDoc = itemQuery.docs.first;

        int currentStock =
            int.tryParse(itemDoc['Opening_Stock'].toString()) ?? 0;

        if (currentStock < requestQty) {
          throw "Insufficient stock for ${item['item_name']}";
        }

        batch.update(itemDoc.reference, {
          "Opening_Stock": currentStock - requestQty,
        });
      }

      batch.update(orderDoc.reference, {
        "store_status": "issued",
        "issued_at": FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Order Issued Successfully!",
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
          ),
        );
      }
    }
  }
}