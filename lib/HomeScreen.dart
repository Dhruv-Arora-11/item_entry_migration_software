import 'package:app/store/reading_store.dart';
import 'package:flutter/material.dart';
import 'package:app/store/add_item_inGrp.dart';
import 'package:app/store/add_new_grp.dart';
import 'package:app/store/editing_existing_grp.dart';

class HomeScreen extends StatelessWidget {
  final current_user;

  HomeScreen({
    required this.current_user,
    super.key,
  });

  bool can(String key) {
    return current_user?['permissions']?[key] == true;
  }

  Widget buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF1D4E89)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16)
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Store Manager"),
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F7FB), Color(0xFFEAF2FB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage Store",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102A43),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Create groups, add items, and manage access easily.",
              style: TextStyle(color: Color(0xFF52606D)),
            ),
            const SizedBox(height: 20),
            Column(
              children: [
                // 🔹 CREATE
                if (can("create"))
                  buildCard(
                    context: context,
                    title: "Create Group",
                    subtitle: "Add a new item group",
                    icon: Icons.add_box_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddNewGroup()),
                      );
                    },
                  ),

                if (can("update"))
                  buildCard(
                    context: context,
                    title: "Update Group",
                    subtitle: "Add users or subgroups",
                    icon: Icons.edit_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddToExistingGroup()),
                      );
                    },
                  ),

                if (can("read"))
                  buildCard(
                    context: context,
                    title: "View Groups",
                    subtitle: "Read all groups",
                    icon: Icons.visibility_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ViewGroupsScreen()),
                      );
                    },
                  ),

                // 🔹 ADD ITEM (you can treat as create/update)
                if (can("create") || can("update"))
                  buildCard(
                    context: context,
                    title: "Add Item",
                    subtitle: "Add items to existing groups",
                    icon: Icons.inventory_2_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const add_item()),
                      );
                    },
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
