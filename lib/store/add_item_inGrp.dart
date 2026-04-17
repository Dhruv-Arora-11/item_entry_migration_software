import 'package:app/core/global_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class add_item extends StatefulWidget {
  const add_item({super.key});

  @override
  _add_itemState createState() => _add_itemState();
}

class _add_itemState extends State<add_item> {
  String? selectedGroup;
  String? selectedSubgroup;
  final TextEditingController itemNumberController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController designController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();

  List<String> groups = [];
  Map<String, List<String>> subgroups = {};
  bool isLoading = true;

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

  String get productName {
    if (selectedGroup != null &&
        selectedSubgroup != null &&
        itemNumberController.text.isNotEmpty) {
      return "${selectedGroup!}-${selectedSubgroup!}-${itemNumberController.text}";
    }
    return "Product Name will appear here";
  }
  
  get http => null;

  Future<void> saveItem() async {
  if (selectedGroup == null ||
      selectedSubgroup == null ||
      itemNumberController.text.isEmpty) {
    _showError("Fill required fields");
    return;
  }

  try {
    String itemCode = productName;

    String color = colorController.text.trim();
    String design = designController.text.trim();
    int stock = int.tryParse(stockController.text) ?? 0;
    int size = int.tryParse(sizeController.text) ?? 0;

    String systemIP = await getSystemIP(); // ✅ use your function
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

    String groupName = groupData['name'] ?? selectedGroup;

    // ✅ 1. update group
    await FirebaseFirestore.instance
        .collection("groups")
        .doc(doc.id)
        .update({
      "items": FieldValue.arrayUnion([itemCode])
    });

    // ✅ 2. save full item
    await FirebaseFirestore.instance.collection("Items").add({
      "Color": color,
      "Design_No": design,
      "Opening_Stock": stock,
      "Size": size,

      "Group_ID": selectedGroup,
      "Group_Name": groupName,

      "SubGroup_ID": selectedSubgroup,
      "SubGroup_Name": selectedSubgroup,

      "Item_Code": itemCode,
      "Item_Name": "",
      "Print_Name": "",

      "Created_By": userName,
      "User_Name": userName,

      "System_IP": systemIP,

      "Create_at": FieldValue.serverTimestamp(),

      "Minimum_Stock": 0,
      "Unit": "",
      "Status": true,
    });

    _showSuccess("Item Added Successfully!");

    // clear fields
    itemNumberController.clear();
    colorController.clear();
    designController.clear();
    stockController.clear();
    sizeController.clear();

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
    itemNumberController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchGroups();
  }

  Future<void> fetchGroups() async {
    try {
      var snapshot =
          await FirebaseFirestore.instance.collection("groups").get();

      List<String> tempGroups = [];
      Map<String, List<String>> tempSubgroups = {};

      for (var doc in snapshot.docs) {
        var data = doc.data();

        String shortDesc = data['short_des'] ?? "";
        List sub = List.from(data['subgroups'] ?? []);

        if (shortDesc.isNotEmpty) {
          tempGroups.add(shortDesc);
          tempSubgroups[shortDesc] = sub.map((e) => e.toString()).toList();
        }
      }

      setState(() {
        groups = tempGroups;
        subgroups = tempSubgroups;
        selectedGroup = null;
        selectedSubgroup = null;
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Store Manager",
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
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
                                "Create a structured product entry",
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: const Color(0xFF102A43),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Select the category, refine the subgroup, and assign an item number to generate a consistent product name.",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF52606D),
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 28),
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: "Short Desc of Group",
                                  prefixIcon: Icon(Icons.category_outlined),
                                ),
                                value: selectedGroup,
                                items: groups
                                    .map((group) => DropdownMenuItem(
                                          value: group,
                                          child: Text(group),
                                        ))
                                    .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedGroup = val;
                                    selectedSubgroup = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 18),
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: "Subgroup",
                                  prefixIcon: Icon(Icons.account_tree_outlined),
                                ),
                                value: selectedSubgroup,
                                items: selectedGroup == null
                                    ? []
                                    : subgroups[selectedGroup]!
                                        .map((subgroup) => DropdownMenuItem(
                                              value: subgroup,
                                              child: Text(subgroup),
                                            ))
                                        .toList(),
                                onChanged: (val) {
                                  setState(() {
                                    selectedSubgroup = val;
                                  });
                                },
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: itemNumberController,
                                decoration: const InputDecoration(
                                  labelText: "Item Number",
                                  prefixIcon: Icon(Icons.tag_outlined),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                "Generated Product Name",
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: const Color(0xFF52606D),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF8FBFF),
                                      Color(0xFFEEF4FA)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                      color: const Color(0xFFD9E2EC)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Color(0xFF1D4E89),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        productName,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: const Color(0xFF102A43),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              const SizedBox(height: 18),
                              TextField(
                                controller: colorController,
                                decoration: const InputDecoration(
                                  labelText: "Color",
                                  prefixIcon: Icon(Icons.color_lens_outlined),
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: designController,
                                decoration: const InputDecoration(
                                  labelText: "Design Number",
                                  prefixIcon:
                                      Icon(Icons.design_services_outlined),
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: stockController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Opening Stock",
                                  prefixIcon: Icon(Icons.inventory_outlined),
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextField(
                                controller: sizeController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Size",
                                  prefixIcon: Icon(Icons.straighten_outlined),
                                ),
                              ),
                              
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    saveItem();
                                  },
                                  icon: const Icon(Icons.add_business_outlined),
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
