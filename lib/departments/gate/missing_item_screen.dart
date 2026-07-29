import 'package:app/services/missing_item_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MissingItemsReportScreen extends StatefulWidget {
  final String gateEntryNo;
  const MissingItemsReportScreen({super.key, required this.gateEntryNo});

  @override
  State<MissingItemsReportScreen> createState() => _MissingItemsReportScreenState();
}

class _MissingItemsReportScreenState extends State<MissingItemsReportScreen> {
  final MissingItemService _service = MissingItemService();
  final TextEditingController _reasonCtrl = TextEditingController();
  List<Map<String, dynamic>> selectedItems = [];

  void _openSearchDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const ItemSearchDialog(),
    );
    if (result != null) {
      setState(() => selectedItems.add(result));
    }
  }

  Future<void> _submitReport() async {
    if (selectedItems.isEmpty || _reasonCtrl.text.isEmpty) return;
    
    await _service.reportMissingItems(
      gateEntryNo: widget.gateEntryNo, 
      items: selectedItems, 
      reason: _reasonCtrl.text
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Report sent to Super Admin")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Missing Items")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _openSearchDialog,
              icon: const Icon(Icons.search),
              label: const Text("Search & Add Missing Item"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: selectedItems.length,
                itemBuilder: (ctx, i) => Card(
                  child: ListTile(
                    title: Text(selectedItems[i]['item_description']),
                    subtitle: Text("Code: ${selectedItems[i]['item_code']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => selectedItems.removeAt(i)),
                    ),
                  ),
                ),
              ),
            ),
            TextField(
              controller: _reasonCtrl,
              decoration: const InputDecoration(labelText: "Reason for reporting", border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: _submitReport,
                child: const Text("Submit Report to Super Admin"),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// 🔹 Reused Search Dialog Logic
class ItemSearchDialog extends StatefulWidget {
  const ItemSearchDialog({super.key});
  @override
  State<ItemSearchDialog> createState() => _ItemSearchDialogState();
}

class _ItemSearchDialogState extends State<ItemSearchDialog> {
  String query = "";
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(decoration: const InputDecoration(hintText: "Search item name..."), onChanged: (v) => setState(() => query = v.toLowerCase())),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection("Items").snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return Expanded(child: const CircularProgressIndicator());
                  var docs = snapshot.data!.docs.where((d) => (d['Item_Name'] as String).toLowerCase().contains(query)).toList();
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      var data = docs[i].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['Item_Name']),
                        onTap: () => Navigator.pop(context, {"item_description": data['Item_Name'], "item_code": data['Item_Code']}),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}