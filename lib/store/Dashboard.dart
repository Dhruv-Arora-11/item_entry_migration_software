import 'package:app/Excel_exporting/all_grps_and_subgrps.dart';
import 'package:app/party/NewPartyForm.dart';
import 'package:app/departments/FIBC/FIBC_WorkOrderNo.dart';
import 'package:app/departments/gate/pending_gate_entries.dart';
import 'package:app/party/PartyListScreen.dart';
import 'package:app/store/purchase_order/making_purchase_orders_reciepts.dart';
import 'package:app/store/FIBC_Part/StoreFulFillmentPage.dart';
import 'package:app/store/FIBC_Part/production_log_page.dart';
import 'package:app/store/request/StoreRequestPage.dart';
import 'package:app/store/viewing_item.dart';
import 'package:flutter/material.dart';
import 'package:app/store/add_item.dart';
import 'package:app/store/add_new_grp.dart';
import 'package:app/store/addSubGroup.dart';

import '../departments/gate/entries_register_screen.dart';

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
                          MaterialPageRoute(
                              builder: (_) => const AddNewGroup()),
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

                  // 🔹 ADD ITEM
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

                  buildCard(
                    context: context,
                    title: "Verify Gate Entries",
                    subtitle: "Approve incoming material and update stock",
                    icon: Icons.domain_verification_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PendingGateEntriesScreen(),
                        ),
                      );
                    },
                  ),

                  buildCard(
                    context: context,
                    title: "Gate Entries Register",
                    subtitle: "View history of all approved gate entries",
                    icon: Icons.history_edu_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GateEntriesRegisterScreen(),
                        ),
                      );
                    },
                  ),

                  // Registering/Managing Parties
                  buildCard(
                    context: context,
                    title: "Party Master",
                    subtitle: "Register and manage your vendors",
                    icon: Icons.business,
                    onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PartyListScreen(
        collectionName: "party_master",
        title: "Party",
        fields: [
          'Vendor_Name', 'Group Name', 'GST', 'PAN_No', 'Address', 'Address2', 'Contact_No', 'Contact_Person', 
          'Bank_Name', 'Bank_Account_No', 'Bank_Account_Holder_Name', 'Bank_IFSC', 
          'email', 'MSME_No', 'VCode'
        ],
      ),
    ),
  );
},
                  ),

// Registering/Managing Customers
                  buildCard(
                    context: context,
                    title: "Customer Master",
                    subtitle: "Register and manage your customers",
                    icon: Icons.person,
                    onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PartyListScreen(
        collectionName: "Customer_Master",
        title: "Customer",
        fields: [
          'Customer_Name', 'Group Name','GST_No_1', 'GST_No_2', 'PAN_No', 'Address', 'Address2', 
          'Contact_Number', 'Contact_Number2', 'Contact_Person', 'Bank_Name', 
          'Account_No', 'IFSC_Code', 'email', 'email2', 'email_cc', 'Country', 
          'Country2', 'State', 'State2', 'Pincode', 'Pincode2', 'Credit_Period', 'MSME_Reg_No'
        ],
      ),
    ),
  );
}
                  ),
                  buildCard(
                    context: context,
                    title: "Manage Requests",
                    subtitle: "Pending and issued requests",
                    icon: Icons.assignment_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StoreRequestsPage(),
                        ),
                      );
                    },
                  ),

                  // Add this inside the ListView children in StoreDashboard
                  buildCard(
                    context: context,
                    title: "Production Master Log",
                    subtitle: "Track status across all departments",
                    icon: Icons.analytics_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProductionLogPage()),
                      );
                    },
                  ),

                  buildCard(
                    context: context,
                    title: "Create Work Order",
                    subtitle: "Generate a new Work Order from a PO",
                    icon: Icons.assignment_add,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const FibcWorkOrderPage()),
                      );
                    },
                  ),

                  buildCard(
                    context: context,
                    title: "Material Request",
                    subtitle: "Approve the Material Requests from FIBC Dept.",
                    icon: Icons.assignment_add,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MaterialRequestPage()),
                      );
                    },
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  ElevatedButton(
                    onPressed: () async {
                      await exportGroupsToExcelWeb();
                    },
                    child: const Text(
                        "Export Groups and Subgroups to Excel Sheet"),
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
