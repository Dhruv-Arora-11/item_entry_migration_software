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
      // ✅ Check duplicate user
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

      // ✅ Add user
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

      // ✅ Reset fields
      usernameController.clear();
      passwordController.clear();

      setState(() {
        create = false;
        read = false;
        update = false;
        delete = false;
        role = "user";
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
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
            // Username
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: "Username",
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),

            // Password
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),

            // Role Dropdown
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
              onChanged: (val) {
                setState(() {
                  role = val!;
                });
              },
            ),
            const SizedBox(height: 20),

            // Permissions title
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Permissions",
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),

            // Permissions
            CheckboxListTile(
              title: const Text("Create"),
              value: create,
              onChanged: (val) => setState(() => create = val!),
            ),
            CheckboxListTile(
              title: const Text("Read"),
              value: read,
              onChanged: (val) => setState(() => read = val!),
            ),
            CheckboxListTile(
              title: const Text("Update"),
              value: update,
              onChanged: (val) => setState(() => update = val!),
            ),
            CheckboxListTile(
              title: const Text("Delete"),
              value: delete,
              onChanged: (val) => setState(() => delete = val!),
            ),

            const SizedBox(height: 20),

            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : createUser,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create User"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}