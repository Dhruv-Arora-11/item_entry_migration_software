import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Loomefficiencyentrysystem extends StatefulWidget {
  const Loomefficiencyentrysystem({super.key});

  @override
  State<Loomefficiencyentrysystem> createState() =>
      _LoomefficiencyentrysystemState();
}

class _LoomefficiencyentrysystemState
    extends State<Loomefficiencyentrysystem> {
  final _formKey = GlobalKey<FormState>();

  // Header Controllers
  final shiftController = TextEditingController();
  final remarkController = TextEditingController();

  // Data Controllers
  final loomNoController = TextEditingController();
  final sizeController = TextEditingController();
  final rollTypeController = TextEditingController();
  final qualityController = TextEditingController();
  final colourController = TextEditingController();
  final meshController = TextEditingController();
  final gramController = TextEditingController();
  final reqMtrsController = TextEditingController();
  final finalMtrsController = TextEditingController();
  final efficiencyController = TextEditingController();
  final netWeightController = TextEditingController();
  final operatorController = TextEditingController();
  final rowRemarkController = TextEditingController();

  Future<void> saveEntry() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await FirebaseFirestore.instance
          .collection('loom_efficiency_entries')
          .add({
        'bookName': 'OWN PRODUCTION',
        'entryDate': DateTime.now().toString().split(' ')[0],
        'shiftNo': shiftController.text.trim(),
        'remark': remarkController.text.trim(),
        'rowEntry': {
          'loomNo': loomNoController.text.trim(),
          'size': sizeController.text.trim(),
          'rollType': rollTypeController.text.trim(),
          'quality': qualityController.text.trim(),
          'colour': colourController.text.trim(),
          'mesh': meshController.text.trim(),
          'gram': gramController.text.trim(),
          'reqMtrs': reqMtrsController.text.trim(),
          'finalMtrs': finalMtrsController.text.trim(),
          'efficiency': efficiencyController.text.trim(),
          'netWeight': netWeightController.text.trim(),
          'operator': operatorController.text.trim(),
          'rowRemark': rowRemarkController.text.trim(),
        },
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entry Saved Successfully")),
      );

      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error : $e")),
      );
    }
  }

  void _clearFields() {
    shiftController.clear();
    remarkController.clear();
    loomNoController.clear();
    sizeController.clear();
    rollTypeController.clear();
    qualityController.clear();
    colourController.clear();
    meshController.clear();
    gramController.clear();
    reqMtrsController.clear();
    finalMtrsController.clear();
    efficiencyController.clear();
    netWeightController.clear();
    operatorController.clear();
    rowRemarkController.clear();
  }

  @override
  void dispose() {
    shiftController.dispose();
    remarkController.dispose();
    loomNoController.dispose();
    sizeController.dispose();
    rollTypeController.dispose();
    qualityController.dispose();
    colourController.dispose();
    meshController.dispose();
    gramController.dispose();
    reqMtrsController.dispose();
    finalMtrsController.dispose();
    efficiencyController.dispose();
    netWeightController.dispose();
    operatorController.dispose();
    rowRemarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Loom Efficiency Entry"),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSection(
                title: "Header Details",
                children: [
                  _buildTextField(
                    controller: shiftController,
                    label: "Shift No",
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: remarkController,
                    label: "Header Remark",
                    maxLines: 2,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildSection(
                title: "Production Details",
                children: [
                  _buildTextField(
                    controller: loomNoController,
                    label: "Loom Number",
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: sizeController,
                    label: "Size",
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: rollTypeController,
                    label: "Roll Type",
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildSection(
                title: "Product Details",
                children: [
                  _buildTextField(
                    controller: qualityController,
                    label: "Quality",
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: colourController,
                    label: "Colour",
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: meshController,
                    label: "Mesh",
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: gramController,
                    label: "Gram",
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildSection(
                title: "Production Output",
                children: [
                  _buildTextField(
                    controller: reqMtrsController,
                    label: "Required Meters",
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: finalMtrsController,
                    label: "Final Meters",
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: efficiencyController,
                    label: "Efficiency %",
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: netWeightController,
                    label: "Net Weight",
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _buildSection(
                title: "Operator Details",
                children: [
                  _buildTextField(
                    controller: operatorController,
                    label: "Operator",
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: rowRemarkController,
                    label: "Remark",
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: saveEntry,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    "SAVE ENTRY",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "Please enter $label";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}