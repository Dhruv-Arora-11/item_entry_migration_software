import 'package:app/services/entry_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EntryDetailsScreen extends StatelessWidget {
  final String entryId;
  EntryDetailsScreen({super.key, required this.entryId});
  
  final EntryService _entryService = EntryService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Entry Details: $entryId")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _entryService.fetchEntryItems(entryId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No items found"));

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

              return Card(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data['item_description'] ?? "",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text("Quantity: ${data['qty'] ?? 0}"),
        Text("Weight: ${data['weight'] ?? 0}"),
      ],
    ),
  ),
);
            },
          );
        },
      ),
    );
  }
}