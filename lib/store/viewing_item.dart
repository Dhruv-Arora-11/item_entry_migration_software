import 'package:app/store/Item_related_services.dart';
import 'package:app/store/item_editing_screen.dart';
import 'package:app/store/migration.dart';
import 'package:app/store/viewing_editing_logs.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class GroupSubgroupItemsView extends StatefulWidget {
  final bool isSuperAdmin;
  const GroupSubgroupItemsView({
    super.key,
    this.isSuperAdmin = false,
  });

  @override
  State<GroupSubgroupItemsView> createState() => _GroupSubgroupItemsViewState();
}

class _GroupSubgroupItemsViewState extends State<GroupSubgroupItemsView> {
  String? selectedGroup;
  String? selectedSubgroup;
  String globalSearchQuery = "";
  
  ValueNotifier<Set<String>> selectedDocIds = ValueNotifier({});
  
  final itemService = ItemService();
  final TextEditingController searchController = TextEditingController();
  
  Timer? _debounce;

  Future<void> toggleEdit(String docId, bool isUnlocked) async {
    await FirebaseFirestore.instance.collection("Items").doc(docId).update({
      "edit_unlocked": !isUnlocked,
      "edit_unlocked_by": "super_admin",
      "edit_unlocked_at": FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUnlocked ? "Edit Locked" : "Edit Unlocked",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder(
          valueListenable: selectedDocIds,
          builder: (context, value, _) {
            return Text(
              value.isEmpty ? "Items Viewer" : "${value.length} Selected",
            );
          },
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: selectedDocIds,
            builder: (context, value, _) {
              if (value.isEmpty) {
                return const SizedBox();
              }
              return IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () async {
                  try {
                    QuerySnapshot snapshot;
                    
                    // 🔹 OPTION 1: Local Search for PDF Export
                    if (globalSearchQuery.isNotEmpty) {
                      snapshot = await FirebaseFirestore.instance.collection("Items").get();
                    } else {
                      if (selectedGroup == null || selectedSubgroup == null) return;
                      snapshot = await FirebaseFirestore.instance
                          .collection("Items")
                          .where("Group_Name", isEqualTo: selectedGroup)
                          .where("SubGroup_Name", isEqualTo: selectedSubgroup)
                          .get();
                    }

                    var allDocs = snapshot.docs;

                    // Apply local filter if searching
                    if (globalSearchQuery.isNotEmpty) {
                      allDocs = allDocs.where((doc) {
                        var d = doc.data() as Map<String, dynamic>;
                        return (d['Item_Name']?.toString().toUpperCase().contains(globalSearchQuery) == true) ||
                               (d['Item_Code']?.toString().toUpperCase().contains(globalSearchQuery) == true) ||
                               (d['Design_No']?.toString().toUpperCase().contains(globalSearchQuery) == true) ||
                               (d['Size']?.toString().toUpperCase().contains(globalSearchQuery) == true);
                      }).toList();
                    }

                    var selectedItems = allDocs
                        .where((e) => value.contains(e.id))
                        .toList();

                    await itemService.exportSelectedItemsPdf(
                      selectedDocs: selectedItems,
                      groupName: globalSearchQuery.isNotEmpty ? "Global Search" : (selectedGroup ?? ""),
                      subgroupName: globalSearchQuery.isNotEmpty ? globalSearchQuery : (selectedSubgroup ?? ""),
                    );
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // 🔹 LEFT PANEL (Search + Groups + Subgroups)
          Container(
            width: 300,
            color: Colors.grey.shade100,
            child: Column(
              children: [
                // 🔥 GLOBAL SEARCH BAR
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: "Search All Items...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: globalSearchQuery.isNotEmpty 
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                globalSearchQuery = "";
                              });
                            },
                          )
                        : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(const Duration(milliseconds: 300), () {
                        setState(() {
                          // Convert to uppercase for case-insensitive matching
                          globalSearchQuery = value.trim().toUpperCase(); 
                        });
                      });
                    },
                  ),
                ),

                // 🔥 GROUPS LIST
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection("groups").snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var docs = snapshot.data!.docs;

                      return ListView(
                        children: docs.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          List subgroups = data['subgroups'] ?? [];

                          return ExpansionTile(
                            title: Text(data['name'] ?? ""),
                            subtitle: Text(data['short_des'] ?? ""),
                            children: subgroups.map<Widget>((s) {
                              String subgroupName = (s is Map<String, dynamic>)
                                  ? s['name'] ?? ""
                                  : s.toString();

                              bool isSelected = selectedSubgroup == subgroupName && globalSearchQuery.isEmpty;

                              return ListTile(
                                title: Text(
                                  subgroupName,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.blue : Colors.black,
                                  ),
                                ),
                                leading: Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                  color: isSelected ? Colors.blue : Colors.grey,
                                ),
                                selected: isSelected,
                                selectedTileColor: Colors.blue.withOpacity(0.08),
                                onTap: () {
                                  setState(() {
                                    selectedGroup = data['name'];
                                    selectedSubgroup = subgroupName;
                                    searchController.clear();
                                    globalSearchQuery = "";
                                  });
                                },
                              );
                            }).toList(),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 🔹 RIGHT PANEL (Items Table)
          Expanded(
            child: _buildRightPanelContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanelContent() {
    if (globalSearchQuery.isEmpty && (selectedGroup == null || selectedSubgroup == null)) {
      return const Center(child: Text("Select a subgroup or search for an item"));
    }

    Stream<QuerySnapshot> itemsStream;
    
    // 🔹 OPTION 1: Stream decision
    if (globalSearchQuery.isNotEmpty) {
      // Listen to the whole collection if searching
      itemsStream = FirebaseFirestore.instance.collection("Items").snapshots();
    } else {
      // Subgroup View
      itemsStream = FirebaseFirestore.instance
          .collection("Items")
          .where("Group_Name", isEqualTo: selectedGroup)
          .where("SubGroup_Name", isEqualTo: selectedSubgroup)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: itemsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No items found"));
        }

        var docs = snapshot.data!.docs;

        // 🔹 OPTION 1: Local Filter Application
        if (globalSearchQuery.isNotEmpty) {
          docs = docs.where((doc) {
            var d = doc.data() as Map<String, dynamic>;
            return (d['Item_Name']?.toString().toUpperCase().contains(globalSearchQuery) == true) ||
                   (d['Item_Code']?.toString().toUpperCase().contains(globalSearchQuery) == true) ||
                   (d['Design_No']?.toString().toUpperCase().contains(globalSearchQuery) == true) ||
                   (d['Size']?.toString().toUpperCase().contains(globalSearchQuery) == true);
          }).toList();
        }

        // Handle case where filter returns no results
        if (docs.isEmpty) {
          return Center(child: Text('No matches found for "$globalSearchQuery"'));
        }

        // SORT BY ITEM NAME
        docs.sort((a, b) {
          var nameA = ((a.data() as Map)['Item_Name'] ?? "").toString().toUpperCase();
          var nameB = ((b.data() as Map)['Item_Name'] ?? "").toString().toUpperCase();
          return nameA.compareTo(nameB);
        });

        double totalAmount = 0;
        double totalStocks = 0;

        for (var doc in docs) {
          var data = doc.data() as Map<String, dynamic>;
          var amt = data['Amount'];
          var stock = data['Opening_Stock'];

          if (amt != null) {
            totalAmount += (amt is num) ? amt.toDouble() : double.tryParse(amt.toString()) ?? 0;
          }
          if (stock != null) {
            totalStocks += (stock is num) ? stock.toDouble() : double.tryParse(stock.toString()) ?? 0;
          }
        }

        return Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 TOP CONTEXT HEADER
                if (globalSearchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Search Results for "$globalSearchQuery" (${docs.length} items)',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),

                // 🔥 TOTAL DISPLAY
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Total Amount", style: TextStyle(fontSize: 13, color: Colors.black54)),
                              const SizedBox(height: 6),
                              Text("Rs. ${totalAmount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Total Stock", style: TextStyle(fontSize: 13, color: Colors.black54)),
                              const SizedBox(height: 6),
                              Text("$totalStocks", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                //  ACTION TOOLBAR
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: "Select All",
                        icon: const Icon(Icons.select_all),
                        onPressed: () {
                          bool allSelected = selectedDocIds.value.length == docs.length;
                          if (allSelected) {
                            selectedDocIds.value = {};
                          } else {
                            selectedDocIds.value = docs.map((e) => e.id).toSet();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.build, color: Colors.orange),
                        tooltip: "Run Migration (Click Once)",
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Migration Started... Check console.")),
                          );
                          await migrateAmountToDouble(); 
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Migration Complete!")),
                            );
                          }
                        },
                      ),
                      IconButton(
                        tooltip: "Export PDF",
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        onPressed: () async {
                          var selectedItems = docs.where((e) => selectedDocIds.value.contains(e.id)).toList();
                          await itemService.exportSelectedItemsPdf(
                            selectedDocs: selectedItems,
                            groupName: globalSearchQuery.isNotEmpty ? "Global Search" : (selectedGroup ?? ""),
                            subgroupName: globalSearchQuery.isNotEmpty ? globalSearchQuery : (selectedSubgroup ?? ""),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // DATA TABLE
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: MediaQuery.of(context).size.width - 300,
                    ),
                    child: DataTable(
                      columnSpacing: 40,
                      headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                      columns: [
                        const DataColumn(label: Text("Select")),
                        const DataColumn(label: Text("Item Code")),
                        const DataColumn(label: Text("Item Name")),
                        const DataColumn(label: Text("Design No")),
                        const DataColumn(label: Text("Stock")),
                        const DataColumn(label: Text("Min")),
                        const DataColumn(label: Text("Size")),
                        const DataColumn(label: Text("Unit")),
                        const DataColumn(label: Text("Amount")),
                        const DataColumn(label: Text("Edit")),
                        const DataColumn(label: Text("Logs")),
                        if (widget.isSuperAdmin) const DataColumn(label: Text("Unlock")),
                      ],
                      rows: docs.map((doc) {
                        var d = doc.data() as Map<String, dynamic>;
                        return DataRow(
                          cells: [
                            DataCell(
                              ValueListenableBuilder(
                                valueListenable: selectedDocIds,
                                builder: (context, value, _) {
                                  return Checkbox(
                                    value: value.contains(doc.id),
                                    onChanged: (checked) {
                                      final updated = Set<String>.from(value);
                                      if (checked == true) {
                                        updated.add(doc.id);
                                      } else {
                                        updated.remove(doc.id);
                                      }
                                      selectedDocIds.value = updated;
                                    },
                                  );
                                },
                              ),
                            ),
                            DataCell(Text(d['Item_Code'] ?? "")),
                            DataCell(Text(d['Item_Name'] ?? "")),
                            DataCell(Text(d['Design_No'] ?? "")),
                            DataCell(Text(d['Opening_Stock']?.toString() ?? "0")),
                            DataCell(Text(d['Min_Stock']?.toString() ?? "0")),
                            DataCell(Text(d['Size']?.toString() ?? "")),
                            DataCell(Text(d['Unit']?.toString() ?? "")),
                            DataCell(Text("Rs. ${d['Amount']?.toString() ?? "0"}")),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  String selectedUnit = d["Unit"] ?? "";
                                  if (selectedUnit == "No") {
                                    d["Unit"] = "Nos";
                                  }
                                  FocusScope.of(context).unfocus();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditItemScreen(docId: doc.id, item: d),
                                    ),
                                  );
                                },
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.history),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ItemLogsScreen(itemId: doc.id),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (widget.isSuperAdmin)
                              DataCell(
                                Builder(
                                  builder: (context) {
                                    bool isUnlocked = d['edit_unlocked'] == true;
                                    return IconButton(
                                      icon: Icon(
                                        isUnlocked ? Icons.lock_open : Icons.lock,
                                        color: isUnlocked ? Colors.green : Colors.red,
                                      ),
                                      onPressed: () => toggleEdit(doc.id, isUnlocked),
                                    );
                                  },
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    selectedDocIds.dispose();
    super.dispose();
  }
}