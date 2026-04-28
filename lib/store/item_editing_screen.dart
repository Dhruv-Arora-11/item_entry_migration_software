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

  @override
  void initState() {
    super.initState();

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
      "Size": size.text,
      "Unit": unit.text,
      "Color": color.text,
      "Opening_Stock": int.tryParse(openingStock.text) ?? 0,
      "Minimum_Stock": int.tryParse(minimumStock.text) ?? 0,
      "Amount": int.tryParse(amount.text) ?? 0,
    };

    await service.updateItem(
      docId: widget.docId,
      oldData: widget.item,
      newData: newData,
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
              decoration: const InputDecoration(labelText: "Size"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: unit,
              decoration: const InputDecoration(labelText: "Unit"),
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
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Opening Stock"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: minimumStock,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Minimum Stock"),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
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