import 'package:app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';


class FieldDefinition {
  final String key;
  final String label;
  final String hint;
  final TextInputType inputType;
  final bool required;

  const FieldDefinition({
    required this.key,
    required this.label,
    this.hint = '',
    this.inputType = TextInputType.text,
    this.required = false,
  });
}

class FieldGroup {
  final String title;
  final List<FieldDefinition> fields;

  const FieldGroup({required this.title, required this.fields});
}

class RequirementMaterialDetailsPage extends StatefulWidget {
  const RequirementMaterialDetailsPage({super.key});

  @override
  State<RequirementMaterialDetailsPage> createState() =>
      _RequirementMaterialDetailsPageState();
}

class _RequirementMaterialDetailsPageState
    extends State<RequirementMaterialDetailsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isSubmitting = false;

  final List<FieldGroup> _groups = const [
    FieldGroup(title: 'Order Details', fields: [
      FieldDefinition(
        key: 'PO',
        label: 'Purchase Order',
        hint: 'Enter PO number',
        required: true,
      ),
      FieldDefinition(
        key: 'Work OrderNo',
        label: 'Work Order No.',
        hint: 'Enter work order number',
        required: true,
      ),
      FieldDefinition(
        key: 'Qty',
        label: 'Order Quantity',
        hint: 'Enter total quantity',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'BagSize (LWH by P.O.)',
        label: 'Bag Size (L x W x H)',
        hint: 'Enter bag dimensions from PO',
      ),
      FieldDefinition(
        key: 'P.O Image Uploaded',
        label: 'PO Image Uploaded',
        hint: 'Enter image of BoM',
      ),
    ]),
    FieldGroup(title: 'Required Material Details', fields: []),
    FieldGroup(title: 'Body Fabric', fields: [
      FieldDefinition(
        key: 'Body Fabric Size in No (MM Only)',
        label: 'Body Fabric Size (MM)',
        hint: 'Enter size in MM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Body Fabric GSM in No',
        label: 'Body Fabric GSM',
        hint: 'Enter GSM value',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Body Fabric Meter in No',
        label: 'Body Fabric Meter',
        hint: 'Enter meter requirement',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Body Fabric KG in No',
        label: 'Body Fabric KG',
        hint: 'Enter weight in KG',
        inputType: TextInputType.number,
      ),
    ]),
    FieldGroup(title: 'Side Fabric', fields: [
      FieldDefinition(
        key: 'Side Fabric Size in No (MM Only)',
        label: 'Side Fabric Size (MM)',
        hint: 'Enter size in MM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Side Fabric GSM in No',
        label: 'Side Fabric GSM',
        hint: 'Enter GSM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Side Fabric Meter in No',
        label: 'Side Fabric Meter',
        hint: 'Enter meter requirement',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Side Fabric KG in No',
        label: 'Side Fabric KG',
        hint: 'Enter weight in KG',
        inputType: TextInputType.number,
      ),
    ]),
    FieldGroup(title: 'Top Panel Fabric', fields: [
      FieldDefinition(
        key: 'Top Panel Fabric Size in No (MM Only)',
        label: 'Top Panel Fabric Size (MM)',
        hint: 'Enter size in MM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Top Panel Fabric GSM in No',
        label: 'Top Panel Fabric GSM',
        hint: 'Enter GSM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Top Panel Fabric Meter in No',
        label: 'Top Panel Fabric Meter',
        hint: 'Enter meter requirement',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Top Panel Fabric KG in No',
        label: 'Top Panel Fabric KG',
        hint: 'Enter weight in KG',
        inputType: TextInputType.number,
      ),
    ]),
    FieldGroup(title: 'Top Spout Fabric', fields: [
      FieldDefinition(
        key: 'Top Spout Fabric Size in No (MM Only)',
        label: 'Top Spout Fabric Size (MM)',
        hint: 'Enter size in MM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Top Spout Fabric GSM in No',
        label: 'Top Spout Fabric GSM',
        hint: 'Enter GSM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Top Spout Fabric Meter in No',
        label: 'Top Spout Fabric Meter',
        hint: 'Enter meter requirement',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Top Spout Fabric KG in No',
        label: 'Top Spout Fabric KG',
        hint: 'Enter weight in KG',
        inputType: TextInputType.number,
      ),
    ]),
    FieldGroup(title: 'Bottom Panel Fabric', fields: [
      FieldDefinition(
        key: 'Bottom Panel Fabric Size in No (MM Only)',
        label: 'Bottom Panel Fabric Size (MM)',
        hint: 'Enter size in MM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Bottom Panel Fabric GSM in No',
        label: 'Bottom Panel Fabric GSM',
        hint: 'Enter GSM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Bottom Panel Fabric Meter in No',
        label: 'Bottom Panel Fabric Meter',
        hint: 'Enter meter requirement',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Bottom Panel Fabric KG in No',
        label: 'Bottom Panel Fabric KG',
        hint: 'Enter weight in KG',
        inputType: TextInputType.number,
      ),
    ]),
    FieldGroup(title: 'Bottom Spout Fabric', fields: [
      FieldDefinition(
        key: 'Bottom Spout Fabric Size in No (MM Only)',
        label: 'Bottom Spout Fabric Size (MM)',
        hint: 'Enter size in MM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Bottom Spout Fabric GSM in No',
        label: 'Bottom Spout Fabric GSM',
        hint: 'Enter GSM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Bottom Spout Fabric Meter in No',
        label: 'Bottom Spout Fabric Meter',
        hint: 'Enter meter requirement',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Bottom Spout Fabric KG in No',
        label: 'Bottom Spout Fabric KG',
        hint: 'Enter weight in KG',
        inputType: TextInputType.number,
      ),
    ]),
    FieldGroup(title: 'Accessories', fields: [
      FieldDefinition(
        key: 'Loop Size in MM',
        label: 'Loop Size (MM)',
        hint: 'Enter loop size in MM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Loop GPM',
        label: 'Loop GPM',
        hint: 'Enter loop GPM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Loop Qty in MTR',
        label: 'Loop Quantity (MTR)',
        hint: 'Enter quantity in meters',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Loop Qty in KG',
        label: 'Loop Quantity (KG)',
        hint: 'Enter quantity in KG',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Tie Size in MM',
        label: 'Tie Size (MM)',
        hint: 'Enter tie size in MM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Tie GPM',
        label: 'Tie GPM',
        hint: 'Enter tie GPM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Tie Qty in MTR',
        label: 'Tie Quantity (MTR)',
        hint: 'Enter tie quantity in meters',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Tie Qty in KG',
        label: 'Tie Quantity (KG)',
        hint: 'Enter tie quantity in KG',
        inputType: TextInputType.number,
      ),
    ]),
    FieldGroup(title: 'Liner Details', fields: [
      FieldDefinition(
        key: 'Liner Size in MM',
        label: 'Liner Size (MM)',
        hint: 'Enter liner size in MM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Liner Cut Size in MM',
        label: 'Liner Cut Size (MM)',
        hint: 'Enter cut size in MM',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Liner Thickness in Micron',
        label: 'Liner Thickness (Micron)',
        hint: 'Enter thickness in micron',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Liner Qty in Pcs',
        label: 'Liner Quantity (Pcs)',
        hint: 'Enter quantity in pieces',
        inputType: TextInputType.number,
      ),
      FieldDefinition(
        key: 'Liner Qty in KG',
        label: 'Liner Quantity (KG)',
        hint: 'Enter quantity in KG',
        inputType: TextInputType.number,
      ),
    ]),
  ];

  @override
  void initState() {
    super.initState();
    for (final group in _groups) {
      for (final field in group.fields) {
        _controllers[field.key] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final data = <String, dynamic>{};
      for (final entry in _controllers.entries) {
        data[entry.key] = entry.value.text.trim();
      }

      await FirebaseFirestore.instance
          .collection('RequirementOfMaterialDetails')
          .add(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Material requirement saved successfully.'),
        ),
      );
      _formKey.currentState!.reset();
      for (final controller in _controllers.values) {
        controller.clear();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save data. Please try again.\n$error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _fieldDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.indigo.shade700, width: 2),
      ),
    );
  }

  Widget _buildField(FieldDefinition field) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: _controllers[field.key],
        keyboardType: field.inputType,
        textInputAction: TextInputAction.next,
        decoration: _fieldDecoration(field.label, field.hint),
        validator: (value) {
          if (field.required && (value == null || value.trim().isEmpty)) {
            return 'Please enter ${field.label.toLowerCase()}.';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSection(FieldGroup group) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ...group.fields.map(_buildField),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Requirement of Material Details'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Clear form',
            onPressed: _isSubmitting
                ? null
                : () {
                    _formKey.currentState?.reset();
                    for (final controller in _controllers.values) {
                      controller.clear();
                    }
                  },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Please provide the complete material requirement details below. All values are saved to Firestore for production planning.',
                      style: TextStyle(
                          fontSize: 15, height: 1.5, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Form(
                key: _formKey,
                child: Column(
                  children: _groups.map(_buildSection).toList(),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      _isSubmitting ? 'Saving...' : 'Save Requirement',
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
