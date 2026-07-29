import 'package:app/services/Create_Fetch_Approve_GateEntries.dart'; // Adjust path if needed
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../store/store_receipt_screen.dart'; // 🔥 Updated import

class PendingGateEntriesScreen extends StatelessWidget {
  PendingGateEntriesScreen({super.key});
  final GateService _gateService = GateService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Store Receipts")),
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 CHANGED: Uses the updated method name from the new GateService
        stream: _gateService.fetchPendingGateEntries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No pending entries"));

          return Column(
            children: [
              // Summary Dashboard
              SizedBox(
                height: 100,
                width: double.infinity,
                child: Card(
                  margin: const EdgeInsets.all(12),
                  color: Colors.blue.shade50,
                  child: Center(
                    child: Text(
                      "${snapshot.data!.docs.length} Pending Entries",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        // 🔥 CHANGED: vendor_name to party based on the new schema
                        title: Text(data['party'] ?? "Unknown Party", style: const TextStyle(fontWeight: FontWeight.bold)),
                        // 🔥 CHANGED: Added Bill No to the subtitle for better context
                        subtitle: Text("Gate No: ${doc.id}\nBill No: ${data['bill_no']} • Vehicle: ${data['vehicle_no']}"),
                        isThreeLine: true,
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                // 🔥 CHANGED: Navigating to the new StoreReceiptScreen with correct parameters
                                builder: (_) => StoreReceiptScreen(
                                  gateEntryNo: doc.id, 
                                  gateData: data
                                ),
                              ),
                            );
                          },
                          child: const Text("Create GR"),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}