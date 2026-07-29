import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StitchingDepartmentPage extends StatefulWidget {
  const StitchingDepartmentPage({super.key});

  @override
  State<StitchingDepartmentPage> createState() => _StitchingDepartmentPageState();
}

class _StitchingDepartmentPageState extends State<StitchingDepartmentPage> {
  final TextEditingController orderNoController = TextEditingController();
  final TextEditingController itemRefController = TextEditingController();
  final TextEditingController bagSizeController = TextEditingController();
  final TextEditingController finishedBagsController = TextEditingController();
  final TextEditingController repairBagsController = TextEditingController();
  final TextEditingController rejectBagsController = TextEditingController();
  final TextEditingController lineWastageController = TextEditingController();

  String? selectedWorkOrder;

 Future<void> _saveStitchingData() async {
  if (selectedWorkOrder == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Work Order")));
    return;
  }

  await FirebaseFirestore.instance.collection('stitching_data').add({
    'order_no': selectedWorkOrder, // Now this links perfectly to the log
    'item_ref_no': itemRefController.text,
    'bag_size': bagSizeController.text,
    'finished_bags': int.tryParse(finishedBagsController.text) ?? 0,
    'repair_bags': int.tryParse(repairBagsController.text) ?? 0,
    'rejected_bags': int.tryParse(rejectBagsController.text) ?? 0,
    'line_wastage_kg': double.tryParse(lineWastageController.text) ?? 0,
    'timestamp': FieldValue.serverTimestamp(),
  });

  ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Stitching data saved successfully!")));
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Stitching Department")),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Replace the Order No TextField with this Dropdown
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
          // ... rest of your TextFields (remove orderNoController)
          TextField(controller: itemRefController, decoration: const InputDecoration(labelText: "Items/Reference No")),
            TextField(controller: itemRefController, decoration: const InputDecoration(labelText: "Items/Reference No")),
            TextField(controller: bagSizeController, decoration: const InputDecoration(labelText: "Bag Size")),
            TextField(controller: finishedBagsController, decoration: const InputDecoration(labelText: "No of Bag Finished"), keyboardType: TextInputType.number),
            TextField(controller: repairBagsController, decoration: const InputDecoration(labelText: "No of Bag Repairing"), keyboardType: TextInputType.number),
            TextField(controller: rejectBagsController, decoration: const InputDecoration(labelText: "No of Bag Rejection"), keyboardType: TextInputType.number),
            TextField(controller: lineWastageController, decoration: const InputDecoration(labelText: "Line Wastage (kg)"), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveStitchingData, child: const Text("Submit Stitching Data")),
          ],
        ),
      ),
    );
  }
}