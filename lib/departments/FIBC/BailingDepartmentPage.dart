import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BailingDepartmentPage extends StatefulWidget {
  const BailingDepartmentPage({super.key});

  @override
  State<BailingDepartmentPage> createState() => _BailingDepartmentPageState();
}

class _BailingDepartmentPageState extends State<BailingDepartmentPage> {
  final TextEditingController orderNoController = TextEditingController();
  final TextEditingController itemRefController = TextEditingController();
  final TextEditingController piecesPerBallController = TextEditingController();
  final TextEditingController totalBallsController = TextEditingController();
  final TextEditingController grossWeightController = TextEditingController();
  final TextEditingController tareWeightController = TextEditingController();
  
  String? generatedBallId;
  String? selectedWorkOrder;

  @override
  void initState() {
    super.initState();
    _generateBallId();
  }

  // Logic for FIBC/Financial Year/Six Digits 
  Future<void> _generateBallId() async {
    final now = DateTime.now();
    final startYear = now.month >= 4 ? now.year : now.year - 1;
    final fiscalYear = '$startYear-${(startYear + 1).toString().substring(2)}';
    
    final querySnapshot = await FirebaseFirestore.instance
        .collection('bailing_data')
        .orderBy('created_at', descending: true)
        .limit(1)
        .get();

    int nextSequence = 1;
    if (querySnapshot.docs.isNotEmpty) {
      final lastId = querySnapshot.docs.first['ball_id'] as String;
      final parts = lastId.split('/');
      nextSequence = int.parse(parts.last) + 1;
    }
    
    setState(() {
      generatedBallId = 'FIBC/$fiscalYear/${nextSequence.toString().padLeft(6, '0')}';
    });
  }

Future<void> _saveBailingData() async {
  if (selectedWorkOrder == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a Work Order")));
    return;
  }

  final netWeight = (double.tryParse(grossWeightController.text) ?? 0) - 
                    (double.tryParse(tareWeightController.text) ?? 0);

  await FirebaseFirestore.instance.collection('bailing_data').add({
    'ball_id': generatedBallId,
    'order_no': selectedWorkOrder, // Now this links perfectly to the log
    'item_ref_no': itemRefController.text,
    'pieces_in_ball': int.tryParse(piecesPerBallController.text) ?? 0,
    'no_of_balls_completed': int.tryParse(totalBallsController.text) ?? 0,
    'gross_weight': double.tryParse(grossWeightController.text) ?? 0,
    'tare_weight': double.tryParse(tareWeightController.text) ?? 0,
    'net_weight': netWeight,
    'created_at': FieldValue.serverTimestamp(),
  });

  ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bailing data saved successfully!")));
}
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Bailing Department")),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text("Generated Ball ID: ${generatedBallId ?? 'Generating...'}", 
               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          
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
            TextField(controller: piecesPerBallController, decoration: const InputDecoration(labelText: "Pieces in One Ball"), keyboardType: TextInputType.number),
            TextField(controller: totalBallsController, decoration: const InputDecoration(labelText: "No of Ball Completed"), keyboardType: TextInputType.number),
            TextField(controller: grossWeightController, decoration: const InputDecoration(labelText: "Gross Weight"), keyboardType: TextInputType.number),
            TextField(controller: tareWeightController, decoration: const InputDecoration(labelText: "Tare Weight"), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveBailingData, child: const Text("Submit Bailing Data")),
          ],
        ),
      ),
    );
  }
}