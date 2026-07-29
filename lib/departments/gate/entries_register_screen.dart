import 'package:app/services/entry_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'entry_details_screen.dart';

class GateEntriesRegisterScreen extends StatelessWidget {
  GateEntriesRegisterScreen({super.key});
  final EntryService _entryService = EntryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Entries Register")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _entryService.fetchEntries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No approved entries yet"));

          var docs = snapshot.data!.docs;
          
          // Calculate Stats
          int totalEntries = docs.length;
          double totalAmount = 0;
          for (var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            totalAmount += (data['total_amount'] is num) 
                ? (data['total_amount'] as num).toDouble() 
                : double.tryParse(data['total_amount'].toString()) ?? 0;
          }

          return Column(
            children: [
              // Top Statistics
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text("Total Entries", style: TextStyle(color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text("$totalEntries", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const Text("Total Value", style: TextStyle(color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text("₹${totalAmount.toStringAsFixed(0)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Entries List
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    
                    DateTime date = (data['approved_at'] as Timestamp?)?.toDate() ?? DateTime.now();

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(data["party"] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(doc.id, style: const TextStyle(color: Colors.grey)),
                            Text("Vehicle: ${data["vehicle_no"] ?? 'N/A'} • ${date.day}-${date.month}-${date.year}"),
                          ],
                        ),
                        trailing: Text(
                          "₹${data['total_amount']?.toStringAsFixed(2) ?? '0.00'}",
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EntryDetailsScreen(entryId: doc.id),
                            ),
                          );
                        },
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