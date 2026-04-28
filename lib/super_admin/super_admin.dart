import 'package:app/store/Item_related_services.dart';
import 'package:app/store/viewing_item.dart';
import 'package:app/super_admin/adminPermissionScreen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool create = false;
  bool read = false;
  bool update = false;
  bool delete = false;

  String role = "user";
  bool isLoading = false;

  // ✅ CREATE USER
  Future<void> createUser() async {
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter username & password")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      var existing = await FirebaseFirestore.instance
          .collection("users")
          .where("username", isEqualTo: username)
          .get();

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User already exists")),
        );
        setState(() => isLoading = false);
        return;
      }

      await FirebaseFirestore.instance.collection("users").add({
        "username": username,
        "password": password,
        "role": role,
        "permissions": {
          "create": create,
          "read": read,
          "update": update,
          "delete": delete,
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User created successfully")),
      );

      usernameController.clear();
      passwordController.clear();

      setState(() {
        create = read = update = delete = false;
        role = "user";
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
  }

  // 🔓 GIVE PERMISSION
  Future<void> unlockItem(String docId) async {
    await FirebaseFirestore.instance.collection("Items").doc(docId).update({
      "edit_unlocked": true,
      "edit_unlocked_by": "super_admin",
      "edit_unlocked_at": FieldValue.serverTimestamp(),
    });
  }

  // 🔒 LOCK AGAIN
  Future<void> lockItem(String docId) async {
    await FirebaseFirestore.instance.collection("Items").doc(docId).update({
      "edit_unlocked": false,
    });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Super Admin Panel")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 USER CREATION
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(
                labelText: "Role",
                prefixIcon: Icon(Icons.admin_panel_settings),
              ),
              items: const [
                DropdownMenuItem(value: "user", child: Text("User")),
                DropdownMenuItem(
                    value: "super_admin", child: Text("Super Admin")),
              ],
              onChanged: (val) => setState(() => role = val!),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Permissions",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),

            CheckboxListTile(
              title: const Text("Create"),
              value: create,
              onChanged: (v) => setState(() => create = v!),
            ),
            CheckboxListTile(
              title: const Text("Read"),
              value: read,
              onChanged: (v) => setState(() => read = v!),
            ),
            CheckboxListTile(
              title: const Text("Update"),
              value: update,
              onChanged: (v) => setState(() => update = v!),
            ),
            CheckboxListTile(
              title: const Text("Delete"),
              value: delete,
              onChanged: (v) => setState(() => delete = v!),
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : createUser,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create User"),
              ),
            ),

            const SizedBox(height: 30),

            // 🔹 DELETE LOGS
            ElevatedButton(
              onPressed: () async {
                await ItemService().deleteLogsLastNDays(7);
              },
              child: const Text("Delete Logs (7 days)"),
            ),

            const SizedBox(height: 30),


            



            // 🔥 UNLOCKED ITEMS
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Unlocked Items",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            StreamBuilder(
  stream: FirebaseFirestore.instance
      .collection("Items")
      .where("edit_unlocked", isEqualTo: true)
      .snapshots(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }

    var docs = snapshot.data!.docs;


    if (docs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: const Text("No unlocked items"),
      );
    }

    return Column(
      children: docs.map((doc) {
        var d = doc.data();

        return Card(
          child: ListTile(
            title: Text(d['Item_Name'] ?? ""),
            subtitle: Text("Code: ${d['Item_Code']}"),

            // 🟢 GREEN ICON
            leading: const Icon(Icons.lock_open, color: Colors.green),

            // 🔴 LOCK AGAIN BUTTON
            trailing: IconButton(
              icon: const Icon(Icons.lock, color: Colors.red),
              onPressed: () async {
                await lockItem(doc.id);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Edit Locked")),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
  },
),

            ElevatedButton(
  onPressed: () {
    Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const GroupSubgroupItemsView(
      isSuperAdmin: true, // 🔥 KEY LINE
    ),
  ),
);
  },
  child: const Text("Manage Item Permissions"),
),
          ],
        ),
      ),
    );
  }
}
