import 'package:app/store/Item_related_services.dart';
import 'package:app/store/item_editing_screen.dart';
import 'package:app/store/viewing_editing_logs.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'dart:html' as html;

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
  ValueNotifier<Set<String>> selectedDocIds =
    ValueNotifier({});
  final itemService = ItemService();

  Future<void> toggleEdit(String docId, bool isUnlocked) async {
    await FirebaseFirestore.instance.collection("Items").doc(docId).update({
      "edit_unlocked": !isUnlocked,
      "edit_unlocked_by": "super_admin",
      "edit_unlocked_at": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isUnlocked ? "Edit Locked" : "Edit Unlocked",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

  title: ValueListenableBuilder(

  valueListenable: selectedDocIds,

  builder: (context, value, _) {

    return Text(

      value.isEmpty
          ? "Items Viewer"
          : "${value.length} Selected",
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

            if (selectedGroup == null ||
                selectedSubgroup == null) {
              return;
            }

            var snapshot =
                await FirebaseFirestore.instance
                    .collection("Items")
                    .where(
                      "Group_Name",
                      isEqualTo: selectedGroup,
                    )
                    .where(
                      "SubGroup_Name",
                      isEqualTo: selectedSubgroup,
                    )
                    .get();

            var selectedItems =
                snapshot.docs.where(
              (e) =>
                  value.contains(e.id),
            ).toList();

            await itemService
    .exportSelectedItemsPdf(

  selectedDocs: selectedItems,

  groupName: selectedGroup ?? "",

  subgroupName: selectedSubgroup ?? "",
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
          // 🔹 LEFT PANEL (Groups + Subgroups)
          Container(
            width: 300,
            color: Colors.grey.shade100,
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection("groups").snapshots(),
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

                        bool isSelected = selectedSubgroup == subgroupName;

                        return ListTile(
                          title: Text(
                            subgroupName,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected ? Colors.blue : Colors.black,
                            ),
                          ),
                          leading: Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected ? Colors.blue : Colors.grey,
                          ),
                          selected: isSelected,
                          selectedTileColor: Colors.blue.withOpacity(0.08),
                          onTap: () {
                            setState(() {
                              selectedGroup = data['name'];
                              selectedSubgroup = subgroupName;
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

          // 🔹 RIGHT PANEL (Items)
          Expanded(
            child: selectedGroup == null || selectedSubgroup == null
                ? const Center(child: Text("Select a subgroup"))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("Items")
                        .where("Group_Name", isEqualTo: selectedGroup)
                        .where("SubGroup_Name", isEqualTo: selectedSubgroup)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text("No items found"));
                      }

                      var docs = snapshot.data!.docs;

                      // 🔥 SORT BY ITEM NAME
                      docs.sort((a, b) {
                        var nameA =
                            (a['Item_Name'] ?? "").toString().toLowerCase();
                        var nameB =
                            (b['Item_Name'] ?? "").toString().toLowerCase();
                        return nameA.compareTo(nameB);
                      });

                      double totalAmount = 0;
                      double totalStocks = 0;

                      for (var doc in docs) {
                        var data = doc.data() as Map<String, dynamic>;

                        var amt = data['Amount'];
                        var stock = data['Opening_Stock'];

                        // 🔹 AMOUNT
                        if (amt != null) {
                          totalAmount += (amt is num)
                              ? amt.toDouble()
                              : double.tryParse(amt.toString()) ?? 0;
                        }

                        // 🔹 STOCK
                        if (stock != null) {
                          totalStocks += (stock is num)
                              ? stock.toDouble()
                              : double.tryParse(stock.toString()) ?? 0;
                        }
                      }

                      return Align(
                        alignment: Alignment.topLeft,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔥 TOTAL DISPLAY
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // 🔹 TOTAL AMOUNT CARD
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.green.shade200),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Total Amount",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "Rs. ${totalAmount.toStringAsFixed(2)}",
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // 🔹 TOTAL COUNT CARD
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.blue.shade200),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Total Stock",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "$totalStocks",
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),


                              Container(
  padding: const EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  ),

  child: Row(
    mainAxisAlignment:
        MainAxisAlignment.end,

    children: [

      // 🔹 SELECT ALL
      IconButton(

        tooltip: "Select All",

        icon: const Icon(
          Icons.select_all,
        ),

        onPressed: () {

          bool allSelected =
              selectedDocIds.value.length ==
              docs.length;

          if (allSelected) {

            selectedDocIds.value = {};

          } else {

            selectedDocIds.value =
                docs.map((e) => e.id).toSet();
          }
        },
      ),

      // 🔹 PDF EXPORT
      IconButton(

        tooltip: "Export PDF",

        icon: const Icon(
          Icons.picture_as_pdf,
          color: Colors.red,
        ),

        onPressed: () async {

          var selectedItems =
              docs.where(
            (e) => selectedDocIds.value
                .contains(e.id),
          ).toList();

          await itemService
    .exportSelectedItemsPdf(

  selectedDocs: selectedItems,

  groupName: selectedGroup ?? "",

  subgroupName: selectedSubgroup ?? "",
);
        },
      ),
    ],
  ),
),

                              
                              // 🔽 TABLE
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth:
                                        MediaQuery.of(context).size.width - 300,
                                  ),
                                  child: DataTable(
                                    columnSpacing: 40,
                                    headingRowColor: MaterialStateProperty.all(
                                        Colors.blue.shade50),
                                    columns: [
                                      const DataColumn(label: Text("Select")),
                                      const DataColumn(
                                          label: Text("Item Code")),
                                      const DataColumn(
                                          label: Text("Item Name")),
                                      const DataColumn(
                                          label: Text("Design No")),
                                      const DataColumn(label: Text("Stock")),
                                      const DataColumn(label: Text("Min")),
                                      const DataColumn(label: Text("Size")),
                                      const DataColumn(label: Text("Unit")),
                                      const DataColumn(label: Text("Amount")),
                                      const DataColumn(label: Text("Edit")),
                                      const DataColumn(label: Text("Logs")),
                                      if (widget.isSuperAdmin)
                                        const DataColumn(label: Text("Unlock")),
                                    ],
                                    rows: docs.map((doc) {
                                      var d =
                                          doc.data() as Map<String, dynamic>;

                                      

return DataRow(
  
                                        cells: [
                                          DataCell(

  ValueListenableBuilder(

    valueListenable: selectedDocIds,

    builder: (context, value, _) {

      return Checkbox(

        value: value.contains(doc.id),

        onChanged: (checked) {

          final updated =
              Set<String>.from(value);

          if (checked == true) {

            updated.add(doc.id);

          } else {

            updated.remove(doc.id);
          }

          selectedDocIds.value =
              updated;
        },
      );
    },
  ),
),
                                          DataCell(Text(d['Item_Code'] ?? "")),
                                          DataCell(Text(d['Item_Name'] ?? "")),
                                          DataCell(Text(d['Design_No'] ?? "")),
                                          DataCell(Text(
                                              d['Opening_Stock']?.toString() ??
                                                  "0")),
                                          DataCell(Text(
                                              d['Min_Stock']?.toString() ??
                                                  "0")),
                                          DataCell(Text(
                                              d['Size']?.toString() ?? "")),
                                          DataCell(Text(
                                              d['Unit']?.toString() ?? "")),
                                          DataCell(Text(
                                              "Rs. ${d['Amount']?.toString() ?? "0"}")),

                                          // EDIT
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(Icons.edit,
                                                  color: Colors.blue),
                                              onPressed: () {
                                                FocusScope.of(context)
                                                    .unfocus();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        EditItemScreen(
                                                      docId: doc.id,
                                                      item: d,
                                                    ),
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
          builder: (_) => ItemLogsScreen(
            itemId: doc.id,
          ),
        ),
      );
    },
  ),
),

                                          // TOGGLE LOCK
                                          if (widget.isSuperAdmin)
                                            DataCell(
                                              Builder(
                                                builder: (context) {
                                                  bool isUnlocked =
                                                      d['edit_unlocked'] ==
                                                          true;

                                                  return IconButton(
                                                    icon: Icon(
                                                      isUnlocked
                                                          ? Icons.lock_open
                                                          : Icons.lock,
                                                      color: isUnlocked
                                                          ? Colors.green
                                                          : Colors.red,
                                                    ),
                                                    onPressed: () => toggleEdit(
                                                        doc.id, isUnlocked),
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
                  ),
          ),
        ],
      ),
    );
  }
  @override
void dispose() {

  selectedDocIds.dispose();

  super.dispose();
}
}
