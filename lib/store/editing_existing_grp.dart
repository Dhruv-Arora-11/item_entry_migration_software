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

  Future<void> fetchGroups() async {
    var snapshot =
        await FirebaseFirestore.instance.collection("groups").get();

    List<String> temp = [];

    for (var doc in snapshot.docs) {
      var data = doc.data();
      if (data['short_des'] != null) {
        temp.add(data['short_des']);
      }
    }

    setState(() {
      groups = temp.toSet().toList(); // remove duplicates
      selectedGroup = null;
      isLoading = false;
    });
  }

  Future<void> updateGroup() async {
  // ❌ if no group selected
  if (selectedGroup == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select a group")),
    );
    return;
  }

  String subgroup = _subgroupController.text.trim();
  String user = _userController.text.trim();

  // ❌ if both empty
  if (subgroup.isEmpty && user.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enter subgroup or user ID")),
    );
    return;
  }

  try {
    var query = await FirebaseFirestore.instance
        .collection("groups")
        .where("short_des", isEqualTo: selectedGroup)
        .get();

    if (query.docs.isEmpty) return;

    var doc = query.docs.first;

    Map<String, dynamic> data = {};

    if (subgroup.isNotEmpty) {
      data["subgroups"] = FieldValue.arrayUnion([subgroup]);
    }

    if (user.isNotEmpty) {
      data["users_allowed"] = FieldValue.arrayUnion([user]);
    }

    await FirebaseFirestore.instance
        .collection("groups")
        .doc(doc.id)
        .update(data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Updated successfully")),
    );

    _subgroupController.clear();
    _userController.clear();
    selectedGroup = "";

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
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
                    value: groups.contains(selectedGroup)
                        ? selectedGroup
                        : null,
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