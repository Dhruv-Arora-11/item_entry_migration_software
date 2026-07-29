import 'package:app/departments/gate/missing_item_screen.dart';
import 'package:app/services/store_receipt_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


class StoreReceiptScreen extends StatefulWidget {
  final String gateEntryNo;
  final Map<String, dynamic> gateData;
  const StoreReceiptScreen({super.key, required this.gateEntryNo, required this.gateData});

  @override
  State<StoreReceiptScreen> createState() => _StoreReceiptScreenState();
}

class _StoreReceiptScreenState extends State<StoreReceiptScreen> {
  final StoreReceiptService _service = StoreReceiptService();
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    var snapshot = await FirebaseFirestore.instance
        .collection("Gate_Entries")
        .doc(widget.gateEntryNo)
        .collection("Items")
        .get();
        
    setState(() {
      items = snapshot.docs.map((doc) => {
        "id": doc.id,
        "item_description": doc['item_description'],
        "bill_qty": doc['qty'],
        "status": "Confirmed",
      }).toList();
      isLoading = false;
    });
  }

  // Visual helper for the tracking bar
  Widget _buildWorkflowStep(String title, bool isActive, bool isCurrent) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isCurrent ? Colors.orange : (isActive ? Colors.green : Colors.grey),
          child: Icon(isActive ? Icons.check : Icons.circle, size: 14, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(title, style: TextStyle(fontSize: 12, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text("Store Receipt: ${widget.gateEntryNo}")),
      body: Column(
        children: [
          // 🔥 RESTORED: The Workflow Timeline Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildWorkflowStep("Gate", true, false),
                const Icon(Icons.arrow_forward),
                _buildWorkflowStep("Store", true, true), // Current step
                const Icon(Icons.arrow_forward),
                _buildWorkflowStep("Department", false, false),
                const Icon(Icons.arrow_forward),
                _buildWorkflowStep("Accounts", false, false),
              ],
            ),
          ),
          
          // Header Card
          Card(
            margin: const EdgeInsets.all(16),
            child: ListTile(
              title: Text("Party: ${widget.gateData['party']}", style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("Dept: ${widget.gateData['department'] ?? 'Civil'}"),
              trailing: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade400, foregroundColor: Colors.white),
                icon: const Icon(Icons.report_problem),
                label: const Text("Report Missing Items"),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MissingItemsReportScreen(gateEntryNo: widget.gateEntryNo)
                  ));
                },
              ),
            ),
          ),
          
          // Items Table
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Item")),
                  DataColumn(label: Text("Bill Qty")),
                  DataColumn(label: Text("Status")),
                ],
                rows: items.map((item) {
                  return DataRow(cells: [
                    DataCell(Text(item['item_description'])),
                    DataCell(Text(item['bill_qty'].toString())),
                    DataCell(DropdownButton<String>(
                      value: item['status'],
                      items: [
                        'Confirmed', 
                        'Rejected - Quantity Less',
                        'Rejected - Quantity is More' , 
                        'Rejected - Item Not Requested'
                      ]
                          .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (v) => setState(() => item['status'] = v),
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
          
          // Submit Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () async {
                  await _service.generateGR(
                    grNo: "GR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
                    gateEntryNo: widget.gateEntryNo,
                    gateData: widget.gateData,
                    verifiedItems: items,
                  );
                  if (mounted) Navigator.pop(context);
                },
                child: const Text("Generate GR & Send to Dept"),
              ),
            ),
          )
        ],
      ),
    );
  }
}