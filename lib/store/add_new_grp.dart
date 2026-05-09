import 'package:app/store/Item_related_services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddNewGroup extends StatefulWidget {
  const AddNewGroup({super.key});

  @override
  State<AddNewGroup> createState() => _AddNewGroupState();
}

class _AddNewGroupState extends State<AddNewGroup> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _shortdescController = TextEditingController();

  bool _isLoading = false;

  String systemIP = "";
  final service = ItemService();

  @override
  void dispose() {
    _groupNameController.dispose();
    _shortdescController.dispose();
    super.dispose();
  }


  Future<int> getNextGroupNumber() async {
    var ref =
        FirebaseFirestore.instance.collection("counters").doc("group_counter");

    return FirebaseFirestore.instance.runTransaction((tx) async {
      var snap = await tx.get(ref);

      int current = snap.exists ? snap['value'] : 0;
      int next = current + 1;

      tx.set(ref, {"value": next});

      return next;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String groupName = _groupNameController.text.trim();
      String shortDesc = _shortdescController.text.trim();

      int groupNo = await getNextGroupNumber();
      var systemIP = await service.getSystemIP();

      // 🔥 CASE-INSENSITIVE VALUES
      String groupNameLower = groupName.toLowerCase();
      String shortDescLower = shortDesc.toLowerCase();

      // 🔥 FETCH ALL GROUPS
      var snapshot = await FirebaseFirestore.instance
          .collection("groups")
          .get();

      // 🔥 CHECK DUPLICATES
      for (var doc in snapshot.docs) {
        var data = doc.data();

        String existingName =
            (data['name'] ?? "").toString().toLowerCase();

        String existingShort =
            (data['short_des'] ?? "").toString().toLowerCase();

        if (existingName == groupNameLower) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Group already exists")),
          );
          setState(() => _isLoading = false);
          return;
        }

        if (existingShort == shortDescLower) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Short description already exists")),
          );
          setState(() => _isLoading = false);
          return;
        }
      }

      // ✅ SAVE DATA
      Map<String, dynamic> groupData = {
        'items': [],
        'name': groupName,
        'short_des': shortDesc,
        'users_allowed': [],
        'systemIP': systemIP,
        'datetime': FieldValue.serverTimestamp(),
        'subgroups': [],
        "group_no": groupNo,
      };

      await FirebaseFirestore.instance.collection('groups').add(groupData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _shortdescController.clear();
      _groupNameController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Item Group'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter group name' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _shortdescController,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Short Description (Max 4)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter short desc' : null,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Create Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}