import 'dart:math';

import 'package:app/core/global_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class add_item extends StatefulWidget {
  const add_item({super.key});

  @override
  _add_itemState createState() => _add_itemState();
}

class _add_itemState extends State<add_item> {
  String? selectedGroup;
  String? selectedSubgroup;
  String? selectedUnit;

  final TextEditingController itemCodeController = TextEditingController();
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController designController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController minStockController = TextEditingController();

  List<String> groups = [];
  Map<String, List<Map<String, dynamic>>> subgroups = {};
  Map<String, int> subgroupNumbers = {};
  bool isLoading = true;

  Future<int> getNextItemNumber(String groupDocId) async {
    var ref = FirebaseFirestore.instance
        .collection("groups")
        .doc(groupDocId)
        .collection("meta")
        .doc("item_counter");

    return FirebaseFirestore.instance.runTransaction((tx) async {
      var snap = await tx.get(ref);

      int current = snap.exists ? snap['value'] : 0;
      int next = current + 1;

      tx.set(ref, {"value": next});
      return next;
    });
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

  String get generatedItemCode {
    if (selectedGroup == null || selectedSubgroup == null) {
      return "";
    }

    int subgroupNo = subgroupNumbers["$selectedGroup-$selectedSubgroup"] ?? 0;


    return "G- $selectedGroup | SG-$subgroupNo | Auto";
  }

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

 Future<void> fetchGroups() async {
  var snapshot = await FirebaseFirestore.instance.collection("groups").get();

  List<String> tempGroups = [];
  Map<String, List<Map<String, dynamic>>> tempSubgroups = {};
  Map<String, int> tempSubgroupNumbers = {};

  for (var doc in snapshot.docs) {
    var data = doc.data();

    String shortDesc = data['short_des'] ?? "";
    List sub = List.from(data['subgroups'] ?? []);

    List<Map<String, dynamic>> cleanSubgroups = [];

    for (var s in sub) {
      if (s is Map<String, dynamic>) {
        cleanSubgroups.add(s);

        tempSubgroupNumbers["$shortDesc-${s['name']}"] =
            s['subgroup_no'];
      }
    }

    if (shortDesc.isNotEmpty) {
      tempGroups.add(shortDesc);
      tempSubgroups[shortDesc] = cleanSubgroups;
    }
  }

  setState(() {
    groups = tempGroups;
    subgroups = tempSubgroups;
    subgroupNumbers = tempSubgroupNumbers;
    isLoading = false;
  });
}


  Future<void> saveItem() async {
    if (selectedGroup == null ||
        selectedSubgroup == null ||
        itemNameController.text.isEmpty) {
      _showError("Fill required fields");
      return;
    }

    try {
      String systemIP = await getSystemIP();
      String userName = currentUser?['username'] ?? "unknown";

      var query = await FirebaseFirestore.instance
          .collection("groups")
          .where("short_des", isEqualTo: selectedGroup)
          .get();

      if (query.docs.isEmpty) {
        _showError("Group not found");
        return;
      }

      var doc = query.docs.first;
      var groupData = doc.data();
      int groupNo = groupData['group_no'] ?? 0;

      int subgroupNo = subgroupNumbers["$selectedGroup-$selectedSubgroup"] ?? 0;
      int itemNo = await getNextItemNumber(doc.id);

      String itemCode = "$groupNo-$subgroupNo-$itemNo";

      String groupName = groupData['name'] ?? selectedGroup!;

      // 🔥 Update group
      await FirebaseFirestore.instance.collection("groups").doc(doc.id).update({
        "items": FieldValue.arrayUnion([itemCode])
      });

      // 🔥 Save item
      await FirebaseFirestore.instance.collection("Items").add({
        "Color": colorController.text.trim().isEmpty
            ? "None"
            : colorController.text.trim(),
        "Design_No": designController.text.trim(),
        "Opening_Stock": int.tryParse(stockController.text) ?? 0,
        "Amount": int.tryParse(amountController.text) ?? 0,
        "Size": int.tryParse(sizeController.text) ?? 0,
        "Unit": selectedUnit ?? "",
        "Group_ID": selectedGroup,
        "Group_Name": groupName,
        "SubGroup_ID": selectedSubgroup,
        "SubGroup_Name": selectedSubgroup,
        "Item_Code": itemCode,
        "Item_No": itemNo,
        "Group_No": groupNo,
        "SubGroup_No": subgroupNo,
        "Item_Name": itemNameController.text.trim(),
        "Created_By": userName,
        "User_Name": userName,
        "System_IP": systemIP,
        "Create_at": FieldValue.serverTimestamp(),
        "Status": true,
        "Min_Stock": int.tryParse(minStockController.text) ?? 0
      });

      _showSuccess("Item Added Successfully!");

      // clear
      itemCodeController.clear();
      itemNameController.clear();
      colorController.clear();
      designController.clear();
      stockController.clear();
      amountController.clear();
      sizeController.clear();
      minStockController.clear();
    } catch (e) {
      _showError("Error: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  @override
  void dispose() {
    itemCodeController.dispose();
    itemNameController.dispose();
    colorController.dispose();
    designController.dispose();
    stockController.dispose();
    amountController.dispose();
    sizeController.dispose();
    minStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "ERP-KTPL",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFEAF2FB), Color(0xFFF7F9FC)],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCEBFA),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  "Product Setup",
                                  style: TextStyle(
                                    color: Color(0xFF1D4E89),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),

                              Text(
                                "Create Item",
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 24),

                              // 🔹 GROUP SECTION
                              const Text("Group Info",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),

                              const SizedBox(height: 12),

                              DropdownButtonFormField(
                                value: selectedGroup,
                                decoration: const InputDecoration(
                                  labelText: "Group",
                                  prefixIcon: Icon(Icons.category),
                                ),
                                items: groups
                                    .map((e) => DropdownMenuItem(
                                        value: e, child: Text(e)))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedGroup = val;
                                    selectedSubgroup = null;
                                  });
                                },
                              ),

                              const SizedBox(height: 12),

                              DropdownButtonFormField(
                                value: selectedSubgroup,
                                decoration: const InputDecoration(
                                  labelText: "Subgroup",
                                  prefixIcon: Icon(Icons.account_tree),
                                ),
                                items: selectedGroup == null
                                    ? []
                                    : subgroups[selectedGroup]!
                                        .map((e) => DropdownMenuItem(
                                              value: e['name'],
                                              child: Text(e['name']),
                                            ))
                                        .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedSubgroup = val as String?;
                                  });
                                },
                              ),

                              const SizedBox(height: 20),

                              // 🔹 ITEM SECTION
                              const Text("Item Details",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),

                              const SizedBox(height: 12),

                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: const Color(0xFFD9E2EC)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.qr_code,
                                        color: Color(0xFF1D4E89)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        generatedItemCode.isEmpty
                                            ? "Item Code (Auto Generated)"
                                            : generatedItemCode,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF102A43),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              TextField(
                                controller: itemNameController,
                                decoration: const InputDecoration(
                                  labelText: "Item Name",
                                  prefixIcon: Icon(Icons.label),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // 🔹 Additional DETAILS
                              const Text("Additional Details",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),

                              const SizedBox(height: 12),

                              TextField(
                                controller: colorController,
                                decoration: const InputDecoration(
                                  labelText: "Color",
                                  prefixIcon: Icon(Icons.color_lens),
                                ),
                              ),

                              const SizedBox(height: 12),

                              TextField(
                                controller: designController,
                                decoration: const InputDecoration(
                                  labelText: "Design No",
                                  prefixIcon: Icon(Icons.design_services),
                                ),
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: stockController,
                                      decoration: const InputDecoration(
                                        labelText: "Opening Stock",
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: amountController,
                                      decoration: const InputDecoration(
                                        labelText: "Amount",
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: sizeController,
                                      decoration: const InputDecoration(
                                        labelText: "Size",
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField(
                                      value: selectedUnit,
                                      decoration: const InputDecoration(
                                        labelText: "Unit",
                                      ),
                                      items: [
                                        "No",
                                        "Square Foot",
                                        "Square Meter",
                                        "Meter",
                                        "KG",
                                        "Foot"
                                      ]
                                          .map((e) => DropdownMenuItem(
                                              value: e, child: Text(e)))
                                          .toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          selectedUnit = val;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28),

                              TextField(
                                controller: minStockController,
                                decoration: const InputDecoration(
                                  labelText: "Minimum Stock",
                                ),
                              ),

                              const SizedBox(height: 28),

                              // 🔹 BUTTON
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: saveItem,
                                  icon: const Icon(Icons.add),
                                  label: const Text("Add Product"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
