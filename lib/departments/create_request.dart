import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class CreateRequestScreen extends StatefulWidget {
  final String departmentName;

  const CreateRequestScreen({super.key, required this.departmentName});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  String? selectedGroup;
  String? selectedSubgroup;
  List<Map<String, dynamic>> cartItems = [];

  // Sorting variables
  List<Map<String, dynamic>> _sortedGroups = [];
  bool _groupsPrepared = false;

  String globalSearchQuery = "";
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _printOrder(
    List<Map<String, dynamic>> items,
    String dept,
    String reqNo,
    String date,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("GSTIN: 08AAICK1451A1ZZ", style: const pw.TextStyle(fontSize: 10)),
                  pw.Text("Phones: 9257883555", style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text("KULVIR TEXTILE PRIVATE LIMITED", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold))),
              pw.Center(child: pw.Text("918-919, NANAK PURA, Rampuriya Payra Bus Stop,", style: const pw.TextStyle(fontSize: 10))),
              pw.Center(child: pw.Text("MANDAL, Neem Ka Khera, Bhilwara-311403", style: const pw.TextStyle(fontSize: 10))),
              pw.Center(child: pw.Text("State: RAJASTHAN, Code: 08", style: const pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Requisition No : $reqNo", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text("Date : $date", style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 18),
              pw.Center(child: pw.Text("Order Request : $dept", style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold))),
              pw.SizedBox(height: 18),
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.7),
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                cellStyle: const pw.TextStyle(fontSize: 10),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2.2),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(2.3),
                },
                headers: const ["Code", "Item Name", "Qty", "Due Date"],
                data: items.map((item) {
                  return [
                    item["is_other_item"] == true ? "OTHER" : (item["item_code"] ?? ""),
                    item["item_name"] ?? "",
                    item["requested_qty"].toString(),
                    (item["due_date"] as Timestamp).toDate().toString().split(" ")[0],
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _openRequestDialog(Map<String, dynamic> item) {
    TextEditingController qtyController = TextEditingController();
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item['Item_Name'] ?? "Item"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Quantity", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  var picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDate: DateTime.now(),
                  );
                  if (picked != null) setDialogState(() => dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                  child: Text(dueDate == null ? "Select Due Date" : "Due: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}"),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (qtyController.text.isEmpty || dueDate == null) return;
                setState(() {
                  cartItems.add({
                    "item_code": item['Item_Code'],
                    "item_name": item['Item_Name'],
                    "requested_qty": int.tryParse(qtyController.text) ?? 0,
                    "due_date": Timestamp.fromDate(dueDate!),
                    "is_other_item": false,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text("Add to Cart"),
            ),
          ],
        ),
      ),
    );
  }

  void _openOtherItemDialog() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Request Other Item"),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Item Name", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Quantity", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setDialogState(() => dueDate = picked);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                      child: Text(dueDate == null ? "Select Due Date" : "${dueDate!.day}/${dueDate!.month}/${dueDate!.year}"),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty || qtyController.text.trim().isEmpty || dueDate == null) return;
                  setState(() {
                    cartItems.add({
                      "item_code": "OTHER",
                      "item_name": nameController.text.trim(),
                      "requested_qty": int.parse(qtyController.text),
                      "due_date": Timestamp.fromDate(dueDate!),
                      "is_other_item": true,
                    });
                  });
                  Navigator.pop(context);
                },
                child: const Text("Add to Cart"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (cartItems.isEmpty) return;
    final itemsToPrint = List<Map<String, dynamic>>.from(cartItems);
    final now = DateTime.now();
    final formattedDate = "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
    final reqNo = "REQ-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(8)}";

    try {
      await FirebaseFirestore.instance.collection("requests").add({
        "department": widget.departmentName,
        "status": "pending",
        "created_at": FieldValue.serverTimestamp(),
        "requisition_no": reqNo,
        "request_date": formattedDate,
        "items": cartItems,
      });
      if (mounted) {
        setState(() => cartItems.clear());
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Order Submitted"),
            content: const Text("Your order has been placed successfully."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text("Print Order"),
                onPressed: () {
                  Navigator.pop(context);
                  _printOrder(itemsToPrint, widget.departmentName, reqNo, formattedDate);
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _showCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Cart (${cartItems.length})"),
        content: SizedBox(
          width: 600,
          height: 400,
          child: cartItems.isEmpty
              ? const Center(child: Text("No items in cart"))
              : ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Card(
                      child: ListTile(
                        title: Text(item['item_name'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item["is_other_item"] == true ? "Custom Item" : "Code: ${item['item_code']}"),
                            Text("Qty: ${item['requested_qty']}"),
                            Text("Due: ${item['due_date'] != null ? (item['due_date'] as Timestamp).toDate().toString().split(' ')[0] : 'N/A'}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() => cartItems.removeAt(index));
                            Navigator.pop(context);
                            _showCartDialog();
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          if (cartItems.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _submitOrder();
              },
              icon: const Icon(Icons.send),
              label: const Text("Submit Order"),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Items"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.shopping_cart),
              label: Text("Cart (${cartItems.length})"),
              onPressed: _showCartDialog,
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          _buildLeftPanel(),
          Expanded(child: _buildRightPanel()),
        ],
      ),
      bottomNavigationBar: cartItems.isNotEmpty
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: _submitOrder,
                  icon: const Icon(Icons.send),
                  label: Text("Submit ${cartItems.length} Item(s)"),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      width: 300,
      color: Colors.grey.shade100,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(hintText: "Search...", prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () => setState(() => globalSearchQuery = value.trim().toUpperCase()));
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("groups").snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                // Local sorting logic
                if (!_groupsPrepared || _sortedGroups.length != snapshot.data!.docs.length) {
                  _sortedGroups = snapshot.data!.docs.map((e) => e.data() as Map<String, dynamic>).toList();
                  
                  // Sort Groups alphabetically
                  _sortedGroups.sort((a, b) => (a["name"] ?? "").toString().toLowerCase().compareTo((b["name"] ?? "").toString().toLowerCase()));

                  // Sort Subgroups alphabetically
                  for (var group in _sortedGroups) {
                    List subs = List.from(group["subgroups"] ?? []);
                    subs.sort((a, b) {
                      final nA = a is Map ? (a["name"] ?? "") : a.toString();
                      final nB = b is Map ? (b["name"] ?? "") : b.toString();
                      return nA.toLowerCase().compareTo(nB.toLowerCase());
                    });
                    group["subgroups"] = subs;
                  }
                  _groupsPrepared = true;
                }

                return ListView.builder(
                  itemCount: _sortedGroups.length,
                  itemBuilder: (context, index) {
                    final data = _sortedGroups[index];
                    List subgroups = data['subgroups'] ?? [];
                    return ExpansionTile(
                      title: Text(data['name'] ?? ""),
                      children: subgroups.map<Widget>((s) {
                        String name = s is Map ? (s['name'] ?? "") : s.toString();
                        return ListTile(
                          title: Text(name),
                          onTap: () => setState(() {
                            selectedGroup = data['name'];
                            selectedSubgroup = name;
                            globalSearchQuery = "";
                          }),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    final bool showStockColumn = selectedSubgroup?.toUpperCase() != "GENERAL ITEM";
    Stream<QuerySnapshot> stream = globalSearchQuery.isNotEmpty
        ? FirebaseFirestore.instance.collection("Items").snapshots()
        : (selectedGroup != null && selectedSubgroup != null)
            ? FirebaseFirestore.instance
                .collection("Items")
                .where("Group_Name", isEqualTo: selectedGroup)
                .where("SubGroup_Name", isEqualTo: selectedSubgroup)
                .snapshots()
            : const Stream.empty();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _openOtherItemDialog,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text("Request Other Item"),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              if (globalSearchQuery.isEmpty && (selectedGroup == null || selectedSubgroup == null)) {
                return const Center(child: Text("Select a category or search"));
              }
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              var docs = snapshot.data!.docs;
              
              // Sort locally
              docs.sort((a, b) {
                final da = a.data() as Map<String, dynamic>;
                final db = b.data() as Map<String, dynamic>;
                return (da['Item_Name'] ?? '').toString().toLowerCase().compareTo((db['Item_Name'] ?? '').toString().toLowerCase());
              });

              // Filter locally
              if (globalSearchQuery.isNotEmpty) {
                docs = docs.where((doc) {
                  var d = doc.data() as Map<String, dynamic>;
                  return (d['Item_Name']?.toString().toUpperCase().contains(globalSearchQuery) ?? false) ||
                         (d['Item_Code']?.toString().toUpperCase().contains(globalSearchQuery) ?? false);
                }).toList();
              }

              return SingleChildScrollView(
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text("Code")),
                    const DataColumn(label: Text("Name")),
                    if (showStockColumn) const DataColumn(label: Text("Stock")),
                    const DataColumn(label: Text("Action")),
                  ],
                  rows: docs.map((doc) {
                    var d = doc.data() as Map<String, dynamic>;
                    return DataRow(cells: [
                      DataCell(Text(d['Item_Code'] ?? "")),
                      DataCell(Text(d['Item_Name'] ?? "")),
                      if (showStockColumn)
                        DataCell(Text((d['Opening_Stock'] ?? 0).toString())),
                      DataCell(ElevatedButton(
                        onPressed: () => _openRequestDialog(d), 
                        child: const Text("Request")
                      )),
                    ]);
                  }).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}