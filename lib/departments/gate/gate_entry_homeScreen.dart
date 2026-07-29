import 'package:app/services/Create_Fetch_Approve_GateEntries.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class GateEntryScreen extends StatefulWidget {
  const GateEntryScreen({super.key});

  @override
  State<GateEntryScreen> createState() => _GateEntryScreenState();
}

class _GateEntryScreenState extends State<GateEntryScreen> {
  final _partyCtrl = TextEditingController();
  final _billCtrl = TextEditingController();
  final _challanCtrl = TextEditingController();
  final _vehicleCtrl = TextEditingController();
  
  final GateService _gateService = GateService();
  
  List<Map<String, dynamic>> items = [];
  List<String> departmentList = [];
  String? selectedDepartment; 
  bool isDeptLoading = true;

  void _loadDepartments() {
    _gateService.fetchDepartments().listen((snapshot) {
      if (mounted) {
        setState(() {
          // IMPORTANT: Ensure 'name' matches your Firestore field name (e.g., 'Department_Name')
          departmentList = snapshot.docs.map((doc) => doc['name'].toString()).toList();
          
          if (departmentList.isNotEmpty && selectedDepartment == null) {
            selectedDepartment = departmentList.first;
          }
          isDeptLoading = false;
        });
      }
    });
  }
  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Widget buildField(String title, TextEditingController controller, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: title,
          prefixIcon: icon != null ? Icon(icon, color: Colors.blueGrey) : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  // 🔥 NEW: Opens the Smart Search Dialog
  void _openItemSearchDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false, // Force user to use buttons
      builder: (context) => const ItemSearchDialog(),
    );

    if (result != null) {
      setState(() {
        items.add(result);
      });
    }
  }

  Future<void> _submit() async {
    if (_partyCtrl.text.isEmpty || items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Party Name and at least one Item are required!"), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Auto-generate a Gate Entry Number
    String entryNo = "GE-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";

    await _gateService.createGateEntry(
      gateEntryNo: entryNo,
      billNo: _billCtrl.text.trim(),
      challanNo: _challanCtrl.text.trim(),
      party: _partyCtrl.text.trim(),
      vehicleNo: _vehicleCtrl.text.trim(),
      department: selectedDepartment,
      items: items,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Success: $entryNo sent to Store"), backgroundColor: Colors.green),
      );
      
      setState(() {
        _partyCtrl.clear();
        _billCtrl.clear();
        _challanCtrl.clear();
        _vehicleCtrl.clear();
        items.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Gate: Incoming Material Entry"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 LEFT COLUMN: ENTRY FORM
            Expanded(
              flex: 1,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Basic Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      
                      buildField("Party / Vendor Name *", _partyCtrl, icon: Icons.business),
                      buildField("Bill Number", _billCtrl, icon: Icons.receipt_long),
                      buildField("Challan Number", _challanCtrl, icon: Icons.description),
                      buildField("Vehicle Number", _vehicleCtrl, icon: Icons.local_shipping),
                      
                      const SizedBox(height: 10),
                      const Text("Route Approval To:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                      const SizedBox(height: 8),
                      
                      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: isDeptLoading 
          ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text("Select Department"),
                value: selectedDepartment,
                items: departmentList.map((dept) => DropdownMenuItem(value: dept, child: Text(dept))).toList(),
                onChanged: (val) => setState(() => selectedDepartment = val!),
              ),
            ),
      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 24),

            // 🔹 RIGHT COLUMN: ITEMS TABLE & SUBMIT
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Items inside Vehicle", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        // 🔥 Opens the new Search Dialog
                        onPressed: _openItemSearchDialog,
                        icon: const Icon(Icons.search),
                        label: const Text("Search & Add Item"),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: items.isEmpty
                          ? const Center(child: Text("No items added yet. Click 'Search & Add Item'.", style: TextStyle(color: Colors.grey)))
                          : SingleChildScrollView(
                              child: SizedBox(
                                width: double.infinity,
                                child: DataTable(
                                  headingRowColor: MaterialStateProperty.all(Colors.blue.shade50),
                                  columns: const [
                                    DataColumn(label: Text("Code", style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text("Description", style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text("Quantity", style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text("Weight", style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: items.map((e) => DataRow(cells: [
                                    DataCell(Text(e['item_code'] ?? "N/A", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))),
                                    DataCell(Text(e['item_description'])),
                                    DataCell(Text(e['qty'].toString())),
                                    DataCell(Text(e['weight'].toString())),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () => setState(() => items.remove(e)),
                                      ),
                                    ),
                                  ])).toList(),
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800, 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      icon: const Icon(Icons.send),
                      label: const Text("Send To Store for Receipt", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 🔥 UPDATED SMART SEARCH DIALOG
// ============================================================================

class ItemSearchDialog extends StatefulWidget {
  const ItemSearchDialog({super.key});

  @override
  State<ItemSearchDialog> createState() => _ItemSearchDialogState();
}

class _ItemSearchDialogState extends State<ItemSearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  
  String searchQuery = "";
  Timer? _debounce;
  Map<String, dynamic>? selectedItem; 

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(20),
        child: selectedItem == null ? _buildSearchPhase() : _buildInputPhase(),
      ),
    );
  }

  // 🔹 PHASE 1: DYNAMIC FIRESTORE SEARCH
  Widget _buildSearchPhase() {
    // 🔥 Construct the Firestore query dynamically based on what the user types
    Query itemsQuery = FirebaseFirestore.instance.collection("Items");

    if (searchQuery.isNotEmpty) {
      itemsQuery = itemsQuery
          .where("Item_Name", isGreaterThanOrEqualTo: searchQuery)
          .where("Item_Name", isLessThan: "$searchQuery\uf8ff");
    }
    
    // Always limit to prevent accidentally downloading the whole database
    itemsQuery = itemsQuery.limit(50);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Select Item from Master", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: "Type item name to search...",
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            // 🔥 Debounce prevents spamming Firestore reads while typing fast
            if (_debounce?.isActive ?? false) _debounce!.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              setState(() {
                // Converts to uppercase to match your database formatting
                searchQuery = value.trim();
              });
            });
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: itemsQuery.snapshots(), // 🔥 Pass the dynamic query here
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    searchQuery.isEmpty ? "Type to start searching." : "No items found for '$searchQuery'.",
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              var docs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  return Card(
                    elevation: 0,
                    color: Colors.grey.shade100,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(data['Item_Name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Code: ${data['Item_Code'] ?? 'N/A'}  |  Unit: ${data['Unit'] ?? 'N/A'}"),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                      onTap: () {
                        setState(() {
                          // Lock in the item and move to input phase
                          selectedItem = data;
                        });
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.red)),
          ),
        )
      ],
    );
  }

  // 🔹 PHASE 2: ENTERING QUANTITY FOR SELECTED ITEM
  Widget _buildInputPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Enter Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        // Show what was selected
        Card(
          color: Colors.blue.shade50,
          elevation: 0,
          child: ListTile(
            title: Text(selectedItem!['Item_Name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text("Code: ${selectedItem!['Item_Code'] ?? 'N/A'}"),
            trailing: TextButton(
              onPressed: () => setState(() => selectedItem = null), // Go back to search
              child: const Text("Change Item"),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        TextField(
          controller: _qtyCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Received Quantity (in ${selectedItem!['Unit'] ?? 'Units'}) *",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        const SizedBox(height: 16),
        
        TextField(
          controller: _weightCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Weight (Optional)",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        
        const Spacer(),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              onPressed: () {
                if (_qtyCtrl.text.isEmpty) return; // Prevent empty qty

                // Return the structured map back to the main screen
                Navigator.pop(context, {
                  "item_code": selectedItem!['Item_Code'] ?? "",
                  "item_description": selectedItem!['Item_Name'] ?? "",
                  "qty": double.tryParse(_qtyCtrl.text) ?? 0,
                  "weight": double.tryParse(_weightCtrl.text) ?? 0,
                });
              },
              child: const Text("Confirm & Add"),
            ),
          ],
        )
      ],
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _qtyCtrl.dispose();
    _weightCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}