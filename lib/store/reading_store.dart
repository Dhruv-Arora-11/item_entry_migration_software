import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewGroupsScreen extends StatefulWidget {
  const ViewGroupsScreen({super.key});

  @override
  State<ViewGroupsScreen> createState() => _ViewGroupsScreenState();
}

class _ViewGroupsScreenState extends State<ViewGroupsScreen> {
  int? expandedIndex;

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF102A43),
        ),
      ),
    );
  }

  Widget wrapChips(List list) {
    if (list.isEmpty) {
      return const Text(
        "None",
        style: TextStyle(color: Colors.grey),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: list
          .map((e) => Chip(
                label: Text(e.toString()),
                backgroundColor: const Color(0xFFE3F2FD),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Groups")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection("groups").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("No groups found"));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;

              bool isExpanded = expandedIndex == index;

              List items = data['items'] ?? [];
              List subgroups = data['subgroups'] ?? [];
              List users = data['users_allowed'] ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Text(
                        data['name'] ?? "",
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      subtitle: Text(
                        data['short_des'] ?? "",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      trailing: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: const Color(0xFF1D4E89),
                      ),
                      onTap: () {
                        setState(() {
                          expandedIndex = isExpanded ? null : index;
                        });
                      },
                    ),
                    if (isExpanded)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFC),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 System IP
                            Row(
                              children: [
                                const Icon(Icons.computer, size: 16),
                                const SizedBox(width: 6),
                                Text("IP: ${data['systemIP']}"),
                              ],
                            ),

                            const SizedBox(height: 14),

                            // 🔹 Subgroups
                            sectionTitle("Subgroups"),
                            wrapChips(subgroups),

                            const SizedBox(height: 12),

                            // 🔹 Items
                            sectionTitle("Items"),
                            wrapChips(items),

                            const SizedBox(height: 12),

                            // 🔹 Users
                            sectionTitle("Users"),
                            wrapChips(users),
                          ],
                        ),
                      )
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
