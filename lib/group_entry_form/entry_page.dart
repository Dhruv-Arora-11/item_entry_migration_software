import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:app/firebase_options.dart';

class GroupEntryForm extends StatefulWidget {
  const GroupEntryForm({Key? key}) : super(key: key);

  @override
  State<GroupEntryForm> createState() => _GroupEntryFormState();
}

class _GroupEntryFormState extends State<GroupEntryForm> {
  // Form Key Validation के लिए
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> all_records = [];

  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupSDescController = TextEditingController();
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _subgroupController = TextEditingController();

  bool _isLoading = false;

  Future<String> _getSystemIP() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      debugPrint("IP Error: $e");
    }
    return 'Unknown IP';
  }

  Future<void> addItem_userToGroup(String item) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String groupName = _groupNameController.text.trim();
      String userId = _userIdController.text.trim();

      var query = await FirebaseFirestore.instance
          .collection("groups")
          .where("name", isEqualTo: groupName)
          .get();

      // ✅ If group does not exist → create and stop
      if (query.docs.isEmpty) {
        await _submitData();
        return;
      }

      var doc = query.docs.first;

      // ✅ Prepare dynamic update map
      Map<String, dynamic> updateData = {};

      if (item.isNotEmpty) {
        updateData["items"] = FieldValue.arrayUnion([item]);
      }

      if (userId.isNotEmpty) {
        updateData["users_allowed"] = FieldValue.arrayUnion([userId]);
      }

      // ❌ nothing to update
      if (updateData.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Nothing to update")),
        );
        return;
      }

      // ✅ Update Firestore
      await FirebaseFirestore.instance
          .collection("groups")
          .doc(doc.id)
          .update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> addAllToGroup() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String groupName = _groupNameController.text.trim();
      String userId = _userIdController.text.trim();
      String item = _itemController.text.trim();
      String subgroup = _subgroupController.text.trim();

      var query = await FirebaseFirestore.instance
          .collection("groups")
          .where("name", isEqualTo: groupName)
          .get();

      // create group if not exists
      if (query.docs.isEmpty) {
        await _submitData();
        return;
      }

      var doc = query.docs.first;

      Map<String, dynamic> updateData = {};

      if (item.isNotEmpty) {
        updateData["items"] = FieldValue.arrayUnion([item]);
      }

      if (userId.isNotEmpty) {
        updateData["users_allowed"] = FieldValue.arrayUnion([userId]);
      }

      if (subgroup.isNotEmpty) {
        updateData["subgroups"] = FieldValue.arrayUnion([subgroup]);
      }

      if (updateData.isEmpty) return;

      await FirebaseFirestore.instance
          .collection("groups")
          .doc(doc.id)
          .update(updateData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });
    try {
      String systemIp = await _getSystemIP();
      var query = await FirebaseFirestore.instance
          .collection("groups")
          .where("name", isEqualTo: _groupNameController.text.trim())
          .get();

      if (query.docs.isNotEmpty) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Group already exists")),
          );
        }
        return;
      }

      Map<String, dynamic> groupData = {
        'items': [],
        'name': _groupNameController.text.trim(),
        'short_des': _groupSDescController.text.trim(),
        'users_allowed': [_userIdController.text.trim()],
        'systemIP': systemIp,
        'datetime': FieldValue.serverTimestamp(),
        'subgroups': []
      };
      await FirebaseFirestore.instance.collection('groups').add(groupData);

      _groupNameController.clear();
      _groupSDescController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('एरर: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRecords();
  }

  Future<void> fetchRecords() async {
    var snapshot = await FirebaseFirestore.instance.collection("groups").get();

    all_records = snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupSDescController.dispose();
    _userIdController.dispose();
    _itemController.dispose();
    _subgroupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item Group'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Group Description Input
                    TextFormField(
                      controller: _groupNameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name (Group_Name)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter group name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // subgroup feild
                    TextFormField(
                      controller: _subgroupController,
                      decoration: const InputDecoration(
                        labelText: 'Subgroup Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Group Short Description Input
                    TextFormField(
                      controller: _groupSDescController,
                      maxLength: 4,
                      decoration: const InputDecoration(
                        labelText:
                            'Short Description (Group_SDesc) - Max 4 Chars',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.short_text),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter short description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // item input field
                    TextFormField(
                      controller: _itemController,
                      decoration: const InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User ID Input
                    TextFormField(
                      controller: _userIdController,
                      decoration: const InputDecoration(
                        labelText: 'User ID',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_itemController.text.trim().isEmpty &&
                                  _userIdController.text.trim().isEmpty &&
                                  _subgroupController.text.trim().isEmpty) {
                                _submitData(); // only create group
                              } else {
                                addAllToGroup();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Save Group'),
                    ),

                    const SizedBox(height: 20),
                    const Text(
                      'Note: Group Identification is Auto-Generated and System IP Is Stored Automatically.',
                      style: TextStyle(
                          color: Colors.grey, fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Code for individual run this file.////
