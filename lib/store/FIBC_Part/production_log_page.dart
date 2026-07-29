import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductionLogPage extends StatelessWidget {
  const ProductionLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Production Master Log")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('fibc_work_orders').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final wo = snapshot.data!.docs[index];
              final woNo = wo['work_order_no'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ExpansionTile(
                  title: Text("Work Order: $woNo", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("PO: ${wo['po_no']}"),
                  children: [
                    _buildStatusSection(woNo),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusSection(String woNo) {
    // We use a FutureBuilder here to fetch data from multiple collections for this specific WO
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchAllStages(woNo),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator());
        
        final data = snapshot.data!;
        return Column(
          children: data.map((stage) {
            return ListTile(
              dense: true,
              title: Text(stage['stage'], style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: Text(stage['status'], style: TextStyle(color: stage['status'] == "Completed" ? Colors.green : Colors.orange)),
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllStages(String woNo) async {
    List<Map<String, dynamic>> stages = [];

    // 1. Check BOM
    final bom = await FirebaseFirestore.instance.collection('fibc_bom').where('work_order_no', isEqualTo: woNo).get();
    stages.add({'stage': 'BOM Definition', 'status': bom.docs.isNotEmpty ? 'Completed' : 'Pending'});

    // 2. Check Material Request
    final req = await FirebaseFirestore.instance.collection('material_requests').where('work_order_no', isEqualTo: woNo).get();
    stages.add({'stage': 'Material Request', 'status': req.docs.isNotEmpty ? req.docs.first['status'] : 'Pending'});

    // 3. Check Cutting
    final cut = await FirebaseFirestore.instance.collection('cutting_data').where('order_no', isEqualTo: woNo).get();
    stages.add({'stage': 'Cutting', 'status': cut.docs.isNotEmpty ? 'Completed' : 'Pending'});

    // 4. Check Stitching
    final stitch = await FirebaseFirestore.instance.collection('stitching_data').where('order_no', isEqualTo: woNo).get();
    stages.add({'stage': 'Stitching', 'status': stitch.docs.isNotEmpty ? 'Completed' : 'Pending'});

    // 5. Check Bailing
    final bail = await FirebaseFirestore.instance.collection('bailing_data').where('order_no', isEqualTo: woNo).get();
    stages.add({'stage': 'Bailing', 'status': bail.docs.isNotEmpty ? 'Completed' : 'Pending'});

    // 6. Check Dispatch
    final disp = await FirebaseFirestore.instance.collection('dispatch_data').where('order_no', isEqualTo: woNo).get();
    stages.add({'stage': 'Dispatch', 'status': disp.docs.isNotEmpty ? 'Completed' : 'Pending'});

    return stages;
  }
}
