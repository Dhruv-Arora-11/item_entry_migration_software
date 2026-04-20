import 'package:flutter/material.dart';
import 'package:app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

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

  @override
  void dispose() {
    _groupNameController.dispose();
    _shortdescController.dispose();
    super.dispose();
  }

  Future<String> getSystemIP() async {
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      String groupName = _groupNameController.text.trim();
      String subgroup = _shortdescController.text.trim();
      var systemIP = await getSystemIP();

      var name = await FirebaseFirestore.instance
          .collection("groups")
          .where("name", isEqualTo: groupName)
          .get();
      var description = await FirebaseFirestore.instance
          .collection("groups")
          .where("name", isEqualTo: subgroup)
          .get();
      
      if (name.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Group already exists")),
        );
        return;
      }else if(description.docs.isNotEmpty){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("short description already exists")),
        );
        return;
      }

      Map<String, dynamic> groupData = {
        'items': [],
        'name': _groupNameController.text.trim(),
        'short_des': _shortdescController.text.trim(),
        'users_allowed': [],
        'systemIP': systemIP,
        'datetime': FieldValue.serverTimestamp(),
        'subgroups': []
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
              // Group Name
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

              // Short Description
              TextFormField(
                controller: _shortdescController,
                maxLength: 4,
                decoration: const InputDecoration(
                  labelText: 'Short Description (Group_SDesc) - Max 4 Chars',
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
              const SizedBox(height: 32),

              // Button
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_shortdescController.text.trim().isEmpty &&
                            _groupNameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    "Error: Enter both Group name and Sub Group name")),
                          );
                        } else {
                          _submit();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Create Group'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
