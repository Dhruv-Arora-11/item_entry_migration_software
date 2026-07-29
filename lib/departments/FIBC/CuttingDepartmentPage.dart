import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CuttingDepartmentPage extends StatefulWidget {
  const CuttingDepartmentPage({super.key});

  @override
  State<CuttingDepartmentPage> createState() => _CuttingDepartmentPageState();
}

class _CuttingDepartmentPageState extends State<CuttingDepartmentPage> {
  final TextEditingController orderNoController = TextEditingController();
  final TextEditingController itemRefController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  final TextEditingController componentController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController piecesController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController wastageController = TextEditingController();

  String? selectedWorkOrder;

  Future<void> _saveCuttingData() async {
    if (selectedWorkOrder == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Work Order")));
    return;
  }
    await FirebaseFirestore.instance.collection('cutting_data').add({
      'order_no': selectedWorkOrder, // Now this is GUARANTEED to match your log
    'item_ref_no': itemRefController.text,
      'roll_no': rollNoController.text, // Number [cite: 10]
      'component_name': componentController.text, // Alphanumeric [cite: 11]
      'size': sizeController.text, // Alphanumeric [cite: 12]
      'no_of_pieces': int.tryParse(piecesController.text) ?? 0, // Number [cite: 13]
      'weight_kg': double.tryParse(weightController.text) ?? 0, // Number [cite: 14]
      'wastage_kg': double.tryParse(wastageController.text) ?? 0, // Number [cite: 15]
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cutting data saved successfully!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cutting Department")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            StreamBuilder<QuerySnapshot>(
  stream: FirebaseFirestore.instance.collection('fibc_work_orders').snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const CircularProgressIndicator();
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: "Select Work Order"),
      value: selectedWorkOrder,
      items: snapshot.data!.docs.map((doc) {
        return DropdownMenuItem<String>(
          value: doc['work_order_no'].toString(),
          child: Text(doc['work_order_no']),
        );
      }).toList(),
      onChanged: (val) => setState(() => selectedWorkOrder = val),
    );
  },
),
            TextField(controller: itemRefController, decoration: const InputDecoration(labelText: "Items/Reference No")),
            TextField(controller: rollNoController, decoration: const InputDecoration(labelText: "Roll No")),
            TextField(controller: componentController, decoration: const InputDecoration(labelText: "Component Name")),
            TextField(controller: sizeController, decoration: const InputDecoration(labelText: "Size")),
            TextField(controller: piecesController, decoration: const InputDecoration(labelText: "No of pieces"), keyboardType: TextInputType.number),
            TextField(controller: weightController, decoration: const InputDecoration(labelText: "Weight (kg)"), keyboardType: TextInputType.number),
            TextField(controller: wastageController, decoration: const InputDecoration(labelText: "Wastage (kg)"), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveCuttingData, child: const Text("Submit Cutting Data")),
          ],
        ),
      ),
    );
  }
}