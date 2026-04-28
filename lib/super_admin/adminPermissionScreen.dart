import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPermissionScreen extends StatefulWidget {
  const AdminPermissionScreen({super.key});

  @override
  State<AdminPermissionScreen> createState() => _AdminPermissionScreenState();
}

class _AdminPermissionScreenState extends State<AdminPermissionScreen> {
  String? selectedGroup;
  String? selectedSubgroup;

  // 🔓 unlock
  Future<void> unlockItem(String docId) async {
    await FirebaseFirestore.instance.collection("Items").doc(docId).update({
      "edit_unlocked": true,
      "edit_unlocked_at": FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Permission Manager")),
      body: Row(
        children: [

          // 🔹 LEFT PANEL (Groups + Subgroups)
          Expanded(
            flex: 2,
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("groups")
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var groups = snapshot.data!.docs;

                return ListView(
                  children: groups.map((doc) {
                    var d = doc.data();
                    List subs = d['subgroups'] ?? [];

                    return ExpansionTile(
                      title: Text(d['name']),
                      children: subs.map((sub) {
                        String subName = sub['name'];

                        return ListTile(
                          title: Text(subName),
                          selected: selectedSubgroup == subName,
                          onTap: () {
                            setState(() {
                              selectedGroup = d['name'];
                              selectedSubgroup = subName;
                            });
                          },
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // 🔹 RIGHT PANEL (Items)
          Expanded(
            flex: 5,
            child: selectedGroup == null
                ? const Center(child: Text("Select subgroup"))
                : StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection("Items")
                        .where("Group_Name", isEqualTo: selectedGroup)
                        .where("SubGroup_Name",
                            isEqualTo: selectedSubgroup)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      var docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Center(child: Text("No items"));
                      }

                      return SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text("Item")),
                            DataColumn(label: Text("Stock")),
                            DataColumn(label: Text("Status")),
                            DataColumn(label: Text("Action")),
                          ],
                          rows: docs.map((doc) {
                            var d = doc.data();

                            bool unlocked = d['edit_unlocked'] == true;

                            return DataRow(cells: [
                              DataCell(Text(d['Item_Name'] ?? "")),
                              DataCell(
                                  Text(d['Opening_Stock'].toString())),

                              // 🔥 status
                              DataCell(
                                Text(
                                  unlocked ? "Unlocked" : "Locked",
                                  style: TextStyle(
                                    color: unlocked
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ),

                              // 🔥 action
                              DataCell(
                                unlocked
                                    ? IconButton(
                                        icon: const Icon(Icons.lock,
                                            color: Colors.red),
                                        onPressed: () async {
                                          await FirebaseFirestore.instance
                                              .collection("Items")
                                              .doc(doc.id)
                                              .update({
                                            "edit_unlocked": false,
                                          });
                                        },
                                      )
                                    : ElevatedButton(
                                        child:
                                            const Text("Give Permission"),
                                        onPressed: () =>
                                            unlockItem(doc.id),
                                      ),
                              ),
                            ]);
                          }).toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}