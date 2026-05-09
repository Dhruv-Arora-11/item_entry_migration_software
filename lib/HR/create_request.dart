import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  String? selectedGroup;
  String? selectedSubgroup;

  // 🔥 REQUEST DIALOG
  void _openRequestDialog(Map<String, dynamic> item) {
  TextEditingController qty = TextEditingController();
  DateTime? dueDate;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Center(
            child: SizedBox(
              width: 500,
              child: Dialog(
                
                
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
              
                      // 🔹 TITLE
                      Text(
                        item['Item_Name'] ?? "",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              
                      const SizedBox(height: 16),
              
                      // 🔹 QUANTITY
                      TextField(
                        controller: qty,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Enter Quantity",
                          border: OutlineInputBorder(),
                        ),
                      ),
              
                      const SizedBox(height: 16),
              
                      // 🔹 DATE PICKER
                      InkWell(
                        onTap: () async {
                          var picked = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                            initialDate: DateTime.now(),
                          );
              
                          if (picked != null) {
                            setState(() {
                              dueDate = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            dueDate == null
                                ? "Select Due Date"
                                : "Due: ${dueDate!.day}-${dueDate!.month}-${dueDate!.year}",
                            style: TextStyle(
                              color: dueDate == null
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
              
                      const SizedBox(height: 20),
              
                      // 🔹 BUTTONS
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (qty.text.isEmpty || dueDate == null) {
                                  return;
                                }
              
                                await FirebaseFirestore.instance
                                    .collection("requests")
                                    .add({
                                  "item_code": item['Item_Code'],
                                  "item_name": item['Item_Name'],
                                  "requested_qty": int.parse(qty.text),
                                  "department": "HR",
                                  "status": "pending",
                                  "due_date": Timestamp.fromDate(dueDate!),
                                  "created_at":
                                      FieldValue.serverTimestamp(),
                                });
              
                                Navigator.pop(context);
              
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("Request Sent")),
                                );
                              },
                              child: const Text("Submit"),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Items")),
      body: Row(
        children: [

          // 🔹 LEFT PANEL (GROUP + SUBGROUP)
          Container(
            width: 280,
            height: double.infinity,
            color: Colors.grey.shade100,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("groups")
                  .snapshots(),
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
                      children: subgroups.map<Widget>((s) {

                        String subgroupName =
                            (s is Map<String, dynamic>)
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
                              color:
                                  isSelected ? Colors.blue : Colors.black,
                            ),
                          ),
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

          // 🔹 RIGHT PANEL (TABLE)
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

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            var docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return const Center(child: Text("No items found"));
            }

            docs.sort((a, b) {
              return (a['Item_Name'] ?? "")
                  .toString()
                  .compareTo((b['Item_Name'] ?? "").toString());
            });

            return SizedBox.expand(
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 60,
                  headingRowColor:
                      MaterialStateProperty.all(Colors.blue.shade50),
                  columns: const [
                    DataColumn(label: Text("Code")),
                    DataColumn(label: Text("Name")),
                    DataColumn(label: Text("Stock")),
                    DataColumn(label: Text("Action")),
                  ],
                  rows: docs.map((doc) {
                    var d = doc.data() as Map<String, dynamic>;

                    return DataRow(
                      cells: [
                        DataCell(Text(d['Item_Code'] ?? "")),
                        DataCell(Text(d['Item_Name'] ?? "")),
                        DataCell(Text("${d['Opening_Stock'] ?? 0}")),

                        DataCell(
                          ElevatedButton(
                            onPressed: () => _openRequestDialog(d),
                            child: const Text("Request"),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
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
}