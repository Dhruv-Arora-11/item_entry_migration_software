import 'package:app/store/Item_related_services.dart';
import 'package:app/store/viewing_item.dart';
import 'package:app/super_admin/RequestPannel.dart';
import 'package:app/super_admin/missing_items_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  String? selectedDepartment;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController department_controller = TextEditingController();

  bool create = false;
  bool read = false;
  bool update = false;
  bool delete = false;

  String role = "user";
  bool isLoading = false;

  // for creating departments like HR, Productions etc.
  Future<void> createDepartment() async {
    String departmentName = department_controller.text.trim();

    if (departmentName.isEmpty) {
      return;
    }

    var existing = await FirebaseFirestore.instance
        .collection("departments")
        .where(
          "name",
          isEqualTo: departmentName,
        )
        .get();

    if (existing.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Department already exists",
          ),
        ),
      );

      return;
    }

    await FirebaseFirestore.instance.collection("departments").add({
      "name": departmentName,
      "created_at": FieldValue.serverTimestamp(),
    });

    department_controller.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Department Created"),
      ),
    );
  }

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
        "department_name": selectedDepartment,
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

  // 🔥 ACTION CARD (FIXED)
  Widget _actionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Super Admin Panel")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔷 TITLE
                const Text(
                  "User Management",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Create Department",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: department_controller,
                          decoration: const InputDecoration(
                            labelText: "Department Name",
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: createDepartment,
                            child: const Text(
                              "Create Department",
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Departments",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("departments")
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            var docs = snapshot.data!.docs;

                            if (docs.isEmpty) {
                              return const Text(
                                "No departments",
                              );
                            }

                            return Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: docs.map((doc) {
                                var d = doc.data() as Map<String, dynamic>;

                                return Chip(
                                  label: Text(d['name']),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🔷 FORM CARD
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: usernameController,
                          decoration: const InputDecoration(
                            labelText: "Username",
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: "Password",
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: role,
                          decoration: const InputDecoration(
                            labelText: "Role",
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            DropdownMenuItem(
                                value: "user", child: Text("User")),
                            DropdownMenuItem(
                                value: "super_admin",
                                child: Text("Super Admin")),
                            DropdownMenuItem(
                                value: "Department",
                                child: Text("Create Department")),
                          ],
                          onChanged: (val) => setState(() => role = val!),
                        ),
                        if (role == "Department")
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("departments")
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const SizedBox();
                              }

                              var docs = snapshot.data!.docs;

                              return Padding(
                                padding: const EdgeInsets.only(
                                  top: 12,
                                ),
                                child: DropdownButtonFormField(
                                  value: selectedDepartment,
                                  decoration: const InputDecoration(
                                    labelText: "Department",
                                    border: OutlineInputBorder(),
                                  ),
                                  items: docs.map((doc) {
                                    var d = doc.data() as Map<String, dynamic>;

                                    return DropdownMenuItem(
                                      value: d['name'],
                                      child: Text(d['name']),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      selectedDepartment = val.toString();
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Permissions",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Wrap(
                          spacing: 10,
                          children: [
                            FilterChip(
                              label: const Text("Create"),
                              selected: create,
                              onSelected: (v) => setState(() => create = v),
                            ),
                            FilterChip(
                              label: const Text("Read"),
                              selected: read,
                              onSelected: (v) => setState(() => read = v),
                            ),
                            FilterChip(
                              label: const Text("Update"),
                              selected: update,
                              onSelected: (v) => setState(() => update = v),
                            ),
                            FilterChip(
                              label: const Text("Delete"),
                              selected: delete,
                              onSelected: (v) => setState(() => delete = v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : createUser,
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("Create User"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 🔷 ACTIONS
                const Text(
                  "Actions",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 4, // 🔥 Changed from 3 to 4
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 70,
                  ),
                  itemBuilder: (context, index) {
                    final actions = [
                      {
                        "title": "Delete Logs",
                        "icon": Icons.delete,
                        "color": Colors.red,
                        "onTap": () async {
                          await ItemService().deleteLogsLastNDays(7);
                        }
                      },
                      {
                        "title": "Edit Item Permissions",
                        "icon": Icons.lock_open,
                        "color": Colors.orange,
                        "onTap": () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const GroupSubgroupItemsView(
                                      isSuperAdmin: true)));
                        }
                      },
                      {
                        "title": "Manage Requests",
                        "icon": Icons.assignment,
                        "color": Colors.blue,
                        "onTap": () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const RequestPanelScreen()));
                        }
                      },
                      // 🔥 NEW ACTION CARD
                      {
                        "title": "Missing Item Reports",
                        "icon": Icons.warning_amber_rounded,
                        "color": Colors.deepPurple,
                        "onTap": () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const MissingItemsReportDashboard()));
                        }
                      },
                    ];

                    final a = actions[index];
                    return _actionCard(
                      a["title"] as String,
                      a["icon"] as IconData,
                      a["color"] as Color,
                      a["onTap"] as VoidCallback,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
