import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BomEntryPage extends StatefulWidget {
  const BomEntryPage({super.key});

  @override
  State<BomEntryPage> createState() => _BomEntryPageState();
}

class _BomEntryPageState extends State<BomEntryPage> {
  String? selectedWorkOrder;
  final TextEditingController componentController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  List<Map<String, dynamic>> bomItems = [];

  void _addItem() {
    if (componentController.text.isNotEmpty && quantityController.text.isNotEmpty) {
      setState(() {
        bomItems.add({
          "component": componentController.text.trim(),
          "quantity": double.tryParse(quantityController.text) ?? 0,
        });
        componentController.clear();
        quantityController.clear();
      });
    }
  }

  Future<void> _saveBom() async {
    if (selectedWorkOrder == null || bomItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a Work Order and add items.")));
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('fibc_bom').add({
        'work_order_no': selectedWorkOrder,
        'items': bomItems,
        'created_at': FieldValue.serverTimestamp(),
      });
      await FirebaseFirestore.instance.collection('material_requests').add({
      'work_order_no': selectedWorkOrder,
      'requested_items': bomItems,
      'status': 'Pending',
      'requested_at': FieldValue.serverTimestamp(),
    });
      
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("BOM Saved Successfully!")));
      
      setState(() {
        bomItems.clear();
        selectedWorkOrder = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving BOM: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BOM Entry")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('fibc_work_orders').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Select Work Order"),
                  items: snapshot.data!.docs.map((doc) => DropdownMenuItem(
                      value: doc['work_order_no'].toString(), 
                      child: Text(doc['work_order_no']))).toList(),
                  onChanged: (val) => setState(() => selectedWorkOrder = val),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: TextField(controller: componentController, decoration: const InputDecoration(labelText: "Component"))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: quantityController, decoration: const InputDecoration(labelText: "Qty"), keyboardType: TextInputType.number)),
                IconButton(icon: const Icon(Icons.add), onPressed: _addItem),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: bomItems.length,
                itemBuilder: (context, index) => ListTile(
                  title: Text(bomItems[index]['component']),
                  trailing: Text("Qty: ${bomItems[index]['quantity']}"),
                ),
              ),
            ),
            ElevatedButton(onPressed: _saveBom, child: const Text("Save BOM")),
          ],
        ),
      ),
    );
  }
}