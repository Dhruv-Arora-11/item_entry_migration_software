import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddToExistingGroup extends StatefulWidget {
  const AddToExistingGroup({super.key});

  @override
  State<AddToExistingGroup> createState() => _AddToExistingGroupState();
}

class _AddToExistingGroupState extends State<AddToExistingGroup> {
  String? selectedGroup;

  final TextEditingController _subgroupController = TextEditingController();
  final TextEditingController _userController = TextEditingController();

  List<String> groups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<int> getNextSubgroupNumber() async {
    var ref = FirebaseFirestore.instance
        .collection("counters")
        .doc("subgroup_counter");

    return FirebaseFirestore.instance.runTransaction((tx) async {
      var snap = await tx.get(ref);

      int current = snap.exists ? snap['value'] : 0;
      int next = current + 1;

      tx.set(ref, {"value": next});

      return next;
    });
  }

Future<void> fetchGroups() async {
  var snapshot =
      await FirebaseFirestore.instance.collection("groups").get();

  List<String> temp = []; // all short descriptions

  for (var doc in snapshot.docs) {
    var data = doc.data();

    String shortDesc = data['short_des'] ?? "";

    if (shortDesc.isNotEmpty) {
      temp.add(shortDesc);
    }
  }

  setState(() {
    groups = temp.toSet().toList(); // remove duplicates
    selectedGroup = null;
    isLoading = false;
  });
}
Future<void> updateGroup() async {
  if (selectedGroup == null) {
    _show("Please select a group");
    return;
  }

  String subgroup = _subgroupController.text.trim();
  String user = _userController.text.trim();

  if (subgroup.isEmpty && user.isEmpty) {
    _show("Enter subgroup or user ID");
    return;
  }

  try {
    var query = await FirebaseFirestore.instance
        .collection("groups")
        .where("short_des", isEqualTo: selectedGroup)
        .get();

    if (query.docs.isEmpty) return;

    var doc = query.docs.first;
    var docData = doc.data();

    Map<String, dynamic> data = {};

    // 🔹 SUBGROUP FIX (IMPORTANT)
    if (subgroup.isNotEmpty) {
      var existingSubgroups = List.from(docData['subgroups'] ?? []);

      bool exists = false;

      for (var e in existingSubgroups) {
        if (e is Map && e['name'] == subgroup) {
          exists = true;
        } else if (e is String && e == subgroup) {
          exists = true;
        }
      }

      if (exists) {
        _show("Subgroup already exists");
        return;
      }

      int subGroup_number = await getNextSubgroupNumber();

      data["subgroups"] = FieldValue.arrayUnion([
        {
          "name": subgroup,
          "subgroup_no": subGroup_number,
        }
      ]);
    }

    // 🔹 USER FIX
    if (user.isNotEmpty) {
      var users = List.from(docData['users_allowed'] ?? []);

      if (users.contains(user)) {
        _show("User already exists");
        return;
      }

      data["users_allowed"] = FieldValue.arrayUnion([user]);
    }

    await FirebaseFirestore.instance
        .collection("groups")
        .doc(doc.id)
        .update(data);

    _show("Updated successfully");

    _subgroupController.clear();
    _userController.clear();

    setState(() {
      selectedGroup = null;
    });
  } catch (e) {
    _show("Error: $e");
  }
}
  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    _subgroupController.dispose();
    _userController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Update Group")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Select Group (Short Desc)",
                    ),
                    value:
                        groups.contains(selectedGroup) ? selectedGroup : null,
                    items: groups
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedGroup = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _subgroupController,
                    decoration: const InputDecoration(
                      labelText: "Subgroup",
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _userController,
                    decoration: const InputDecoration(
                      labelText: "User ID",
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: updateGroup,
                    child: const Text("Update"),
                  )
                ],
              ),
            ),
    );
  }
}
