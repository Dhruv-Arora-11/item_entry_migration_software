import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DispatchDepartmentPage extends StatefulWidget {
  const DispatchDepartmentPage({super.key});

  @override
  State<DispatchDepartmentPage> createState() => _DispatchDepartmentPageState();
}

class _DispatchDepartmentPageState extends State<DispatchDepartmentPage> {
  final TextEditingController orderNoController = TextEditingController();
  final TextEditingController itemNoController = TextEditingController();
  final TextEditingController ballNoController = TextEditingController();
  final TextEditingController totalBallsController = TextEditingController();
  final TextEditingController netWeightController = TextEditingController();
  final TextEditingController tareWeightController = TextEditingController();
  final TextEditingController grossWeightController = TextEditingController();

  String? selectedWorkOrder;

  Future<void> _saveDispatchData() async {
  if (selectedWorkOrder == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Work Order")));
    return;
  }

  await FirebaseFirestore.instance.collection('dispatch_data').add({
    'order_no': selectedWorkOrder,
    'item_no': itemNoController.text,
    'ball_no': ballNoController.text,
    'total_no_of_balls': int.tryParse(totalBallsController.text) ?? 0,
    'net_weight': double.tryParse(netWeightController.text) ?? 0,
    'tare_weight': double.tryParse(tareWeightController.text) ?? 0,
    'gross_weight': double.tryParse(grossWeightController.text) ?? 0,
    'dispatch_time': FieldValue.serverTimestamp(),
  });

  ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Dispatch details saved successfully!")));
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Dispatch Department")),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Dropdown for guaranteed Work Order matching
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
          TextField(controller: itemNoController, decoration: const InputDecoration(labelText: "Item No")),
          TextField(controller: ballNoController, decoration: const InputDecoration(labelText: "Ball No")),
          TextField(controller: totalBallsController, decoration: const InputDecoration(labelText: "Total No of Balls"), keyboardType: TextInputType.number),
          TextField(controller: netWeightController, decoration: const InputDecoration(labelText: "Net Weight"), keyboardType: TextInputType.number),
          TextField(controller: tareWeightController, decoration: const InputDecoration(labelText: "Tare Weight"), keyboardType: TextInputType.number),
          TextField(controller: grossWeightController, decoration: const InputDecoration(labelText: "Gross Weight"), keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _saveDispatchData, child: const Text("Submit Dispatch")),
        ],
      ),
    ),
  );
}
}