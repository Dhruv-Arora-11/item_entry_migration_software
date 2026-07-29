import 'package:app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class FibcWorkOrderPage extends StatefulWidget {
  const FibcWorkOrderPage({super.key});

  @override
  State<FibcWorkOrderPage> createState() => _FibcWorkOrderPageState();
}

class _FibcWorkOrderPageState extends State<FibcWorkOrderPage> {
  final TextEditingController poNoController = TextEditingController();

  final FocusNode poNoFocusNode = FocusNode();

  final Set<String> existingPoNos = {};
  final List<String> existingWorkOrderNos = [];

  String? generatedWorkOrderNo;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    poNoFocusNode.dispose();
    poNoController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final poSnapshot =
          await FirebaseFirestore.instance.collection('fibc_po').get();
      existingPoNos.clear();
      for (var doc in poSnapshot.docs) {
        final data = doc.data();
        final poNo = data['po_no']?.toString().trim();
        if (poNo != null && poNo.isNotEmpty) {
          existingPoNos.add(poNo);
        }
      }

      final workSnapshot =
          await FirebaseFirestore.instance.collection('fibc_work_orders').get();
      existingWorkOrderNos.clear();
      for (var doc in workSnapshot.docs) {
        final data = doc.data();
        final poNo = data['po_no']?.toString().trim();
        final workOrderNo = data['work_order_no']?.toString().trim();

        if (poNo != null && poNo.isNotEmpty) {
          existingPoNos.add(poNo);
        }
        if (workOrderNo != null && workOrderNo.isNotEmpty) {
          existingWorkOrderNos.add(workOrderNo);
        }
      }

      generatedWorkOrderNo = _buildNextWorkOrderNumber(existingWorkOrderNos);
    } catch (error) {
      _statusMessage = 'Unable to load existing options: $error';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _buildNextWorkOrderNumber(List<String> existingWorkOrders) {
    final now = DateTime.now();
    final startYear = now.month >= 4 ? now.year : now.year - 1;
    final endYear = startYear + 1;
    final fiscalYear = '$startYear-${endYear.toString().substring(2)}';
    var maxSequence = 0;
    for (final woNo in existingWorkOrders) {
      if (woNo.contains('/$fiscalYear')) {
        final match = RegExp(r'KTPL/FIBC-WO-(\d{4})/').firstMatch(woNo);
        if (match != null) {
          final parsed = int.tryParse(match.group(1) ?? '0') ?? 0;
          if (parsed > maxSequence) {
            maxSequence = parsed;
          }
        }
      }
    }

    final nextSequence = (maxSequence + 1).toString().padLeft(4, '0');
    return 'KTPL/FIBC-WO-$nextSequence/$fiscalYear';
  }

 Future<void> _saveWorkOrder() async {
  final poNo = poNoController.text.trim();

  if (poNo.isEmpty) {
    setState(() {
      _statusMessage = 'Please enter Purchase Order Number.';
    });
    return;
  }

  // --- NEW VALIDATION: Verify if PO exists ---
  if (!existingPoNos.contains(poNo)) {
    setState(() {
      _statusMessage = 'Error: Invalid PO Number. Please select a valid existing PO.';
    });
    return;
  }
  // --- END OF VALIDATION ---

  setState(() {
    _isSaving = true;
    _statusMessage = null;
  });

  try {
    // Existing check for duplicate Work Orders
    final existing = await FirebaseFirestore.instance
        .collection('fibc_work_orders')
        .where('po_no', isEqualTo: poNo)
        .get();

    if (existing.docs.isNotEmpty) {
      setState(() {
        _statusMessage = 'Error: A Work Order already exists for this PO Number.';
        _isSaving = false;
      });
      return;
    }

    final newWorkOrderNo = generatedWorkOrderNo ??
        _buildNextWorkOrderNumber(existingWorkOrderNos);
    final now = DateTime.now();

    await FirebaseFirestore.instance.collection('fibc_work_orders').add({
      'po_no': poNo,
      'work_order_no': newWorkOrderNo,
      'current_date_time': Timestamp.fromDate(now),
    });

    existingPoNos.add(poNo);
    existingWorkOrderNos.add(newWorkOrderNo);
    generatedWorkOrderNo = _buildNextWorkOrderNumber(existingWorkOrderNos);

    setState(() {
      _statusMessage = 'Work order saved successfully.';
    });
  } catch (error) {
    setState(() {
      _statusMessage = 'Failed to save work order: $error';
    });
  } finally {
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }
}


  Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String hintText,
    required String labelText,
    required Set<String> optionsSet,
    required FocusNode focusNode,
    VoidCallback? onSubmitted,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return optionsSet.where((option) =>
            option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode fieldFocusNode,
        VoidCallback onFieldSubmitted,
      ) {
        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          onChanged: (value) => controller.text = value,
          onSubmitted: (_) {
            onSubmitted?.call();
          },
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FIBC Work Order'),
        centerTitle: true,
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create New Work Order',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildAutocompleteField(
                      controller: poNoController,
                      hintText: 'Enter Purchase Order Number',
                      labelText: 'Purchase Order Number',
                      optionsSet: existingPoNos,
                      focusNode: poNoFocusNode,
                      onSubmitted: () {
                        FocusScope.of(context).unfocus();
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Auto-generated Work Order Number',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        generatedWorkOrderNo ?? 'Generating...',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text(
                          'Current Date and Time:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateTime.now().toLocal().toString(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveWorkOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Save Work Order',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _statusMessage!.startsWith('Failed')
                              ? Colors.red
                              : Colors.green.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
