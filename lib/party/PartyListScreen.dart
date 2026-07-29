import 'package:app/party/NewPartyForm.dart'; // Ensure this matches your file path
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PartyListScreen extends StatefulWidget {
  final String collectionName;
  final String title;
  final List<String> fields;

  const PartyListScreen({
    super.key,
    required this.collectionName,
    required this.title,
    required this.fields,
  });

  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    // Determine the primary display field based on collection
    String nameField = widget.collectionName == 'Customer_Master' 
        ? 'Customer_Name' 
        : 'Vendor_Name';

    return Scaffold(
      appBar: AppBar(title: Text("Manage ${widget.title}s")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PartyRegistrationForm(
                title: "New ${widget.title}",
                collectionName: widget.collectionName,
                fields: widget.fields,
                existingDocId: null, // Signals New Entry
                existingData: null,
              ),
            ),
          );
        },
        label: Text("Add New ${widget.title}"),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Search by Name...",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => search = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(widget.collectionName)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Filter logic
                var docs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = (data[nameField] ?? "").toString().toLowerCase();
                  return name.contains(search);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("No records found"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    var data = docs[i].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        title: Text(data[nameField] ?? 'No Name'),
                        subtitle: Text(
    "${data['email'] ?? 'No Email'} • Group: ${data['group'] ?? 'General'}"
  ),
                        trailing: const Icon(Icons.edit, size: 18),
                        onTap: () => _navigateToEdit(docs[i].id, data),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToEdit(String docId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartyRegistrationForm(
          title: "Edit ${widget.title}",
          collectionName: widget.collectionName,
          fields: widget.fields,
          existingDocId: docId,
          existingData: data,
        ),
      ),
    );
  }
}