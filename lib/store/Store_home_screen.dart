import 'package:app/Excel_exporting/all_grps_and_subgrps.dart';
import 'package:app/purchase_orde/making_purchase_orders_reciepts.dart';
import 'package:app/store/requests/show_request.dart';
import 'package:app/store/viewing_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:app/store/add_item.dart';
import 'package:app/store/add_new_grp.dart';
import 'package:app/store/addSubGroup.dart';

class StoreDashboard extends StatelessWidget {
  final current_user;

  StoreDashboard({
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
            Expanded(
              child: ListView(
                children: [
                  // 🔹 CREATE
                  if (can("create"))
                    buildCard(
                      context: context,
                      title: "Create Group",
                      subtitle: "Add a new item group",
                      icon: Icons.add_box_outlined,
                      onTap: () {
                        FocusScope.of(context).unfocus();
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
                        FocusScope.of(context).unfocus();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const addingSubgroup()),
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
                        FocusScope.of(context).unfocus();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GroupSubgroupItemsView()),
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
                        FocusScope.of(context).unfocus();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const add_item()),
                        );
                      },
                    ),
              
                  buildCard(
                    context: context,
                    title: "Purchase Order",
                    subtitle: "Create and download purchase orders",
                    icon: Icons.receipt_long_outlined,
                    onTap: () {
                      FocusScope.of(context).unfocus();
              
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PurchaseOrderScreen(),
                        ),
                      );
                    },
                  ),
              
                  const SizedBox(height: 20),
              
              const Text(
                "Store Requests",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF102A43),
                ),
              ),
              
              const SizedBox(height: 12),
              
              SizedBox(
                height: 500,
                child: StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection("requests")
                      .where("status", isEqualTo: "approved")
                      .where("store_status", isEqualTo: "pending")
                      .snapshots(),
                  builder: (context, snapshot) {
              
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
              
                    var docs = snapshot.data!.docs;
              
                    if (docs.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
              child: Text(
                "No Pending Requests",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
                        ),
                      );
                    }
              
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
              
                        var doc = docs[i];
              
                        var d = doc.data();
              
                        return Container(
  margin: const EdgeInsets.only(bottom: 18),

  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ],
  ),

  child: Padding(
    padding: const EdgeInsets.all(20),

    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        // 🔹 TOP
        Row(
          children: [

            Container(
              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FC),
                borderRadius: BorderRadius.circular(16),
              ),

              child: const Icon(
                Icons.inventory_2_rounded,
                color: Color(0xFF1D4E89),
                size: 24,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Text(
                    d['item_name'] ?? "",

                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF102A43),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Requested from ${d['department']}",

                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 7,
              ),

              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(30),
              ),

              child: Text(
                "Pending",

                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 🔹 DETAILS
        Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(16),
          ),

          child: Row(
            children: [

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      "Quantity",

                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "${d['requested_qty']}",

                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    Text(
                      "Item Code",

                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      d['item_code'] ?? "",

                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 🔹 BUTTON
        SizedBox(
          width: double.infinity,

          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D4E89),

              padding: const EdgeInsets.symmetric(
                vertical: 16,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),

              elevation: 0,
            ),

            onPressed: () async {

              await issueItem(
                doc,
                context,
              );
            },

            icon: const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
            ),

            label: const Text(
              "Issue Request",

              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);
                      },
                    );
                  },
                ),
              ),
              
                  SizedBox(
                    height: 15,
                  ),
              
                  ElevatedButton(
                    onPressed: () async {
                      await exportGroupsToExcelWeb();
                    },
                    child:
                        const Text("Export Groups and Subgroups to Excel Sheet"),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
