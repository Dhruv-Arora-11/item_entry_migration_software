import 'package:app/core/global_user.dart';
import 'package:app/store/Item_related_services.dart';
import 'package:flutter/material.dart';

class EditItemScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> item;

  const EditItemScreen({
    super.key,
    required this.docId,
    required this.item,
  });

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final service = ItemService();

  late TextEditingController itemCode;
  late TextEditingController name;
  late TextEditingController design;
  late TextEditingController size;
  late TextEditingController unit;
  late TextEditingController color;
  late TextEditingController openingStock;
  late TextEditingController minimumStock;
  late TextEditingController amount;

  bool isAdmin = false;
  String ip_address = "";


  void initIP() async{
    ip_address = await service.getSystemIP();
  }



  @override
  void initState() {
    super.initState();

    initIP();

    itemCode =
        TextEditingController(text: widget.item['Item_Code'] ?? "");
    name =
        TextEditingController(text: widget.item['Item_Name'] ?? "");
    design =
        TextEditingController(text: widget.item['Design_No'] ?? "");
    size =
        TextEditingController(text: widget.item['Size']?.toString() ?? "");
    unit =
        TextEditingController(text: widget.item['Unit'] ?? "");
    color =
        TextEditingController(text: widget.item['Color'] ?? "");
    openingStock = 
        TextEditingController(text: widget.item['Opening_Stock']?.toString() ?? "0",);
    minimumStock = 
        TextEditingController(text: widget.item['Minimum_Stock']?.toString() ?? "0",);
    amount = 
        TextEditingController(text: widget.item['Amount']?.toString() ?? "0",);
  }

  void save() async {
    if (!service.canEdit(widget.item, isAdmin)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Edit Locked")),
      );
      return;
    }

    Map<String, dynamic> newData = {
      "Item_Code": itemCode.text,
      "Item_Name": name.text,
      "Design_No": design.text,
      "Size": double.tryParse(size.text) ?? 0,
      "Unit": unit.text,
      "Color": color.text,
      "Opening_Stock": double.tryParse(openingStock.text) ?? 0,
      "Minimum_Stock": double.tryParse(minimumStock.text) ?? 0,
      "Amount": double.tryParse(amount.text) ?? 0,
      "ip_address":ip_address,
    };

    await service.updateItem(
      docId: widget.docId,
      oldData: widget.item,
      newData: newData,
      userName: currentUser?['username'] ?? "unknown",
    );

    Navigator.pop(context);
  }

  @override
  void dispose() {
    itemCode.dispose();
    name.dispose();
    design.dispose();
    size.dispose();
    unit.dispose();
    color.dispose();
    openingStock.dispose();
    minimumStock.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Item"),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.lock_open),
              onPressed: () async {
                await service.unlockItem(widget.docId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Unlocked")),
                );
              },
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            TextField(
              controller: itemCode,
              decoration: const InputDecoration(labelText: "Item Code"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: "Item Name"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: design,
              decoration: const InputDecoration(labelText: "Design No"),
            ),
            const SizedBox(height: 20),

            TextField(
  controller: size,
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  decoration: const InputDecoration(labelText: "Size"),
),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
  value: unit.text.isEmpty ? null : unit.text,
  decoration: const InputDecoration(labelText: "Unit"),
  items: ["Nos", "Square Foot", "Square Meter", "KG", "Meter", "Foot"]
      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
      .toList(),
  onChanged: (val) {
    unit.text = val ?? "";
  },
),
            const SizedBox(height: 20),

            TextField(
              controller: color,
              decoration: const InputDecoration(labelText: "Color"),
            ),
            const SizedBox(height: 20),

            // ✅ CORRECT STOCK FIELDS
            TextField(
              controller: openingStock,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Opening Stock"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: minimumStock,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Minimum Stock"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: amount,
              keyboardType:const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: "Amount"),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: save,
              child: const Text("Save Changes"),
            ),
          ],
        ),
      ),
    );
  }
}