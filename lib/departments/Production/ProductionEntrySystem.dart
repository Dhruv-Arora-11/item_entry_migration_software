import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductionEntrySystem extends StatefulWidget {
  const ProductionEntrySystem({super.key,});

  @override
  State<ProductionEntrySystem> createState() => _ProductionEntrySystemState();
}

class _ProductionEntrySystemState extends State<ProductionEntrySystem> {
  final _formKey = GlobalKey<FormState>();

  

  final bookNameController = TextEditingController();
  final entryNoController = TextEditingController();
  final issueDateController = TextEditingController();
  final prodSlipNoController = TextEditingController();
  final remarkController = TextEditingController();

  final loomNoController = TextEditingController();
  final rollNoController = TextEditingController();
  final rollTypeController = TextEditingController();
  final sizeController = TextEditingController();
  final gramController = TextEditingController();
  final tapItemController = TextEditingController();
  final qualityController = TextEditingController();
  final meshController = TextEditingController();
  final colourController = TextEditingController();

  final openingController = TextEditingController();
  final closingController = TextEditingController();
  final finalMtrsController = TextEditingController();
  final grossWeightController = TextEditingController();
  final tareWeightController = TextEditingController();
  final netWeightController = TextEditingController();
  final avgMtrController = TextEditingController();
  final actualGrmController = TextEditingController();

  final partyNameController = TextEditingController();
  final partyGSTController = TextEditingController();

  @override
  void initState() {
    super.initState();
    issueDateController.text = DateTime.now().toString().split(" ").first;
    generateEntryNo();
  }

  Future<void> pickIssueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      issueDateController.text = picked.toString().split(' ').first;
    }
  }

  void calculateValues() {
  final opening = double.tryParse(openingController.text) ?? 0;
  final closing = double.tryParse(closingController.text) ?? 0;
  final gross = double.tryParse(grossWeightController.text) ?? 0;
  final tare = double.tryParse(tareWeightController.text) ?? 0;

  // Final Mtrs
  final finalMtrs = (closing - opening).clamp(0, double.infinity);
  finalMtrsController.text = finalMtrs.toStringAsFixed(2);

  // Net Weight
  final net = (gross - tare).clamp(0, double.infinity);
  netWeightController.text = net.toStringAsFixed(2);

  if (finalMtrs > 0) {
    avgMtrController.text = (net / finalMtrs).toStringAsFixed(2);
    actualGrmController.text =
        ((net * 1000) / finalMtrs).toStringAsFixed(2);
  } else {
    avgMtrController.clear();
    actualGrmController.clear();
  }
}


  Future<void> saveEntry(BuildContext context) async {
    calculateValues();

    await FirebaseFirestore.instance
        .collection(
      "production_entries",
    )
        .add({
      "bookName": bookNameController.text.trim(),
      "entryNo": entryNoController.text.trim(),
      "issueDate": issueDateController.text.trim(),
      "productionSlipNo": prodSlipNoController.text.trim(),
      "remark": remarkController.text.trim(),
      "loomNo": loomNoController.text.trim(),
      "rollNo": rollNoController.text.trim(),
      "rollType": rollTypeController.text.trim(),
      "size": sizeController.text.trim(),
      "gram": gramController.text.trim(),
      "tapItemName": tapItemController.text.trim(),
      "quality": qualityController.text.trim(),
      "mesh": meshController.text.trim(),
      "colour": colourController.text.trim(),
      "openingMtrs": openingController.text.trim(),
      "closingMtrs": closingController.text.trim(),
      "finalMtrs": finalMtrsController.text.trim(),
      "grossWeight": grossWeightController.text.trim(),
      "tareWeight": tareWeightController.text.trim(),
      "netWeight": netWeightController.text.trim(),
      "avgMtr": avgMtrController.text.trim(),
      "actualGrm": actualGrmController.text.trim(),
      "partyName": partyNameController.text.trim(),
      "GST": partyGSTController.text.trim(),
      "createdAt": FieldValue.serverTimestamp(),
    });

    clearForm();
    await generateEntryNo();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Production Entry Saved")),
    );
  }

  Future<void> generateEntryNo() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('production_entries')
        .orderBy('entryNo', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      entryNoController.text = "1";
    } else {
      final lastNo =
          int.tryParse(snapshot.docs.first['entryNo'].toString()) ?? 0;
      entryNoController.text = (lastNo + 1).toString();
    }
  }


  

  Future<List<QueryDocumentSnapshot>> searchParties(String query) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('party_master').get();

    return snapshot.docs.where((doc) {
      final name = doc['Vendor_Name'].toString().toLowerCase();

      return name.contains(query.toLowerCase());
    }).toList();
  }

  void clearForm() {
    for (final c in [
      entryNoController,
      prodSlipNoController,
      remarkController,
      loomNoController,
      rollNoController,
      rollTypeController,
      sizeController,
      gramController,
      tapItemController,
      qualityController,
      meshController,
      colourController,
      openingController,
      closingController,
      finalMtrsController,
      grossWeightController,
      tareWeightController,
      netWeightController,
      avgMtrController,
      actualGrmController,
      partyNameController,
      partyGSTController,
    ]) {
      c.clear();
    }

    issueDateController.text = DateTime.now().toString().split(' ').first;
    bookNameController.text = "JOB PRODUCTION";
  }

  

  @override
  void dispose() {
    for (final c in [
      bookNameController,
      entryNoController,
      issueDateController,
      prodSlipNoController,
      remarkController,
      loomNoController,
      rollNoController,
      rollTypeController,
      sizeController,
      gramController,
      tapItemController,
      qualityController,
      meshController,
      colourController,
      openingController,
      closingController,
      finalMtrsController,
      grossWeightController,
      tareWeightController,
      netWeightController,
      avgMtrController,
      actualGrmController,
      partyNameController,
      partyGSTController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget field(
  String label,
  TextEditingController c, {
  TextInputType type = TextInputType.text,
  bool autoCalculate = false,
  bool required = false,
}) {
  return Padding(
    padding: const EdgeInsets.all(8),
    child: TextFormField(
      controller: c,
      keyboardType: type,
      onChanged: autoCalculate
          ? (_) => calculateValues()
          : null,
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return "$label is required";
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  );
}

  Widget section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  children.map((e) => SizedBox(width: 280, child: e)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Production Entry System"),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              section("Header", [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextFormField(
                    controller: bookNameController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Book Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextFormField(
                    controller: entryNoController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Entry No",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: issueDateController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Issue Date",
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                  
                      if (picked != null) {
                        issueDateController.text =
                            "${picked.day}/${picked.month}/${picked.year}";
                      }
                    },
                  ),
                ),
                field(
  "Production Slip No",
  prodSlipNoController,
  required: true,
),
                field("Remark", remarkController),
              ]),
              section("Production Details", [
                field("Loom No", loomNoController),
                field("Roll No", rollNoController),
                field("Roll Type", rollTypeController),
                field("Size", sizeController),
                field("Gram", gramController, type: TextInputType.number),
                field("Tap Item Name", tapItemController),
                field("Quality", qualityController),
                field("Mesh", meshController),
                field("Colour", colourController),
              ]),
              section("Production Measurements", [
                field(
  "Opening Mtrs",
  openingController,
  type: TextInputType.number,
  autoCalculate: true,
  required: true,
),
                field(
  "Closing Mtrs",
  closingController,
  type: TextInputType.number,
  autoCalculate: true,
  required: true,
),
                Padding(
  padding: const EdgeInsets.all(8),
  child: TextFormField(
    controller: finalMtrsController,
    readOnly: true,
    decoration: InputDecoration(
      labelText: "Final Mtrs",
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
),
                field(
  "Gross Weight",
  grossWeightController,
  type: TextInputType.number,
  autoCalculate: true,
  required: true,
),
                field(
  "Tare Weight",
  tareWeightController,
  type: TextInputType.number,
  autoCalculate: true,
  required: true,
),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextFormField(
                    controller: netWeightController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Net Weight",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: field(
                    "Final Mtrs",
                    finalMtrsController,
                    type: TextInputType.number,
                    autoCalculate: true,
                  ),
                ),
                Padding(
  padding: const EdgeInsets.all(8),
  child: TextFormField(
    controller: actualGrmController,
    readOnly: true,
    decoration: InputDecoration(
      labelText: "Actual GRM",
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
),
              ]),
              section("Party Details", [
                Padding(
  padding: const EdgeInsets.all(8),
  child: Autocomplete<QueryDocumentSnapshot>(
  displayStringForOption: (doc) => doc['Vendor_Name'],

  optionsBuilder: (TextEditingValue textEditingValue) async {
    if (textEditingValue.text.isEmpty) {
      return const Iterable<QueryDocumentSnapshot>.empty();
    }

    return await searchParties(textEditingValue.text);
  },

  onSelected: (QueryDocumentSnapshot doc) {
    partyNameController.text = doc['Vendor_Name'];
    partyGSTController.text = doc['GST'];
  },

  fieldViewBuilder: (
    context,
    textEditingController,
    focusNode,
    onFieldSubmitted,
  ) {
    return TextFormField(
      controller: textEditingController,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: "Party Name",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  },

  // 👇 ADD IT HERE
  optionsViewBuilder: (
    BuildContext context,
    AutocompleteOnSelected<QueryDocumentSnapshot> onSelected,
    Iterable<QueryDocumentSnapshot> options,
  ) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 350,
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: options.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final party = options.elementAt(index);

              return ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.business),
                ),
                title: Text(
                  party['Vendor_Name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text("GST : ${party['GST']}"),
                onTap: () => onSelected(party),
              );
            },
          ),
        ),
      ),
    );
  },
)
),
Padding(
  padding: const EdgeInsets.all(8),
  child: TextFormField(
    controller: partyGSTController,
    readOnly: true,
    decoration: InputDecoration(
      labelText: "GST",
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  ),
),              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
  if (!_formKey.currentState!.validate()) return;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Confirm Save"),
      content: const Text(
        "Are you sure you want to save this production entry?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text("Save"),
        ),
      ],
    ),
  );

  if (confirm == true) {
    await saveEntry(context);
  }
},
                  icon: const Icon(Icons.save),
                  label: const Text("SAVE ENTRY"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
