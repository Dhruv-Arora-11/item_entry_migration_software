import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Design tokens matching the FIBC ERP Interface
class ERPTheme {
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color headerNavy = Color(0xFF1E293B);
  static const Color accentBlue = Color(0xFF0284C7);
  static const Color backgroundBg = Color(0xFFF1F5F9);
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);

  // Button Colors
  static const Color saveBlue = Color(0xFF2563EB);
  static const Color updateGreen = Color(0xFF10B981);
  static const Color clearOrange = Color(0xFFF59E0B);
  static const Color deleteRed = Color(0xFFEF4444);
  static const Color printPurple = Color(0xFF8B5CF6);
}

class FibcPo extends StatefulWidget {
  const FibcPo({super.key});

  @override
  State<FibcPo> createState() => _FibcPoState();
}

class _FibcPoState extends State<FibcPo> {
  final TextEditingController poContactController = TextEditingController();
  final TextEditingController poNameController = TextEditingController();
  final TextEditingController poQtyController = TextEditingController();
  final TextEditingController poRefController = TextEditingController();
  final TextEditingController poNoController = TextEditingController();
  final TextEditingController poEmailController = TextEditingController();
  final TextEditingController poBagLengthController = TextEditingController();
  final TextEditingController poBagWidthController = TextEditingController();
  final TextEditingController poBagHeightController = TextEditingController();
  final TextEditingController poBagColorController = TextEditingController();
  final TextEditingController otherTechSpecification = TextEditingController();
  final TextEditingController safetyFactor = TextEditingController();
  final TextEditingController swl = TextEditingController();
  final TextEditingController constructionStyle = TextEditingController();
  
  final List<Uint8List> _selectedImagesBytes = [];
  final List<String> _selectedImagesNames = [];
  final FocusNode _emailFocusNode = FocusNode();
  
  bool _isSubmitting = false;
  bool _isLoadingData = true;

  // Autocomplete Data Sets
  Set<String> poNos = {};
  Set<String> customerNames = {};
  Set<String> quantities = {};
  Set<String> contactPersons = {};
  Set<String> contactNumbers = {};
  Set<String> emails = {};
  Set<String> bagLengths = {};
  Set<String> bagWidths = {};
  Set<String> bagHeights = {};
  Set<String> swls = {};
  Set<String> constructionStyles = {};
  Set<String> bagColors = {};
  Set<String> otherSpecs = {};
  Set<String> safetyFactors = {
    "2 : 1", "3 : 1", "4 : 1", "5 : 1", "6 : 1", "7 : 1", "8 : 1"
  };

  @override
  void initState() {
    super.initState();
    _fetchUniqueData();
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        if (!poEmailController.text.contains('@') || !poEmailController.text.contains('.')) {
          if (mounted && poEmailController.text.isNotEmpty) {
            _showSnack("Please enter a valid email address containing '@' and '.'", ERPTheme.deleteRed);
          }
        }
      }
    });
  }

  Future<void> _fetchUniqueData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection("fibc_po").get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        void addIfValid(Set<String> set, String key) {
          if (data[key] != null && data[key].toString().isNotEmpty) {
            set.add(data[key].toString());
          }
        }

        addIfValid(poNos, "po_no");
        addIfValid(customerNames, "customer_name");
        addIfValid(quantities, "quantity");
        addIfValid(contactPersons, "contact_person");
        addIfValid(contactNumbers, "contact_number");
        addIfValid(emails, "email");
        addIfValid(bagLengths, "bag_length");
        addIfValid(bagWidths, "bag_width");
        addIfValid(bagHeights, "bag_height");
        addIfValid(swls, "swl");
        addIfValid(safetyFactors, "safety_factor");
        addIfValid(constructionStyles, "construction_style");
        addIfValid(bagColors, "bag_color");
        addIfValid(otherSpecs, "other_tech_spec");
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg, behavior: SnackBarBehavior.floating),
    );
  }

  // --- Image Handling Logic ---
  Future<void> _pickPoImages() async {
    final picker = ImagePicker();
    try {
      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        for (var file in pickedFiles) {
          final bytes = await file.readAsBytes();
          if (!_selectedImagesNames.contains(file.name)) {
            setState(() {
              _selectedImagesBytes.add(bytes);
              _selectedImagesNames.add(file.name);
            });
          }
        }
      }
    } catch (e) {
      if (mounted) _showSnack("Error picking images: $e", ERPTheme.deleteRed);
    }
  }

  Future<String?> _savePoImageToFolder(Uint8List bytes, String fileName) async {
    try {
      final directory = Directory(r'D:\ERP_PO_Image');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final filePath = '${directory.path}\\$uniqueName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      if (mounted) _showSnack('Failed to save image locally: $e', ERPTheme.deleteRed);
      return null;
    }
  }

  Future<String?> _uploadPoImageToStorage(Uint8List bytes, String fileName) async {
    try {
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = FirebaseStorage.instance.ref().child('fibc_po_images/$uniqueName');
      await ref.putData(bytes).timeout(const Duration(seconds: 15));
      return await ref.getDownloadURL().timeout(const Duration(seconds: 15));
    } catch (e) {
      if (mounted) _showSnack('Failed to upload image to storage: $e', ERPTheme.deleteRed);
      return null;
    }
  }

  Future<void> _saveDataToFirebase() async {
    if (poEmailController.text.isNotEmpty && 
       (!poEmailController.text.contains('@') || !poEmailController.text.contains('.'))) {
      _showSnack("Please enter a valid email address.", ERPTheme.deleteRed);
      _emailFocusNode.requestFocus();
      return;
    }

    if (poNoController.text.isEmpty) {
      _showSnack("Please enter a PO Number.", ERPTheme.deleteRed);
      return;
    }

    setState(() => _isSubmitting = true);

    final List<String> imageUrls = [];
    final List<String> localPaths = [];
    for (int i = 0; i < _selectedImagesBytes.length; i++) {
      final downloadUrl = await _uploadPoImageToStorage(_selectedImagesBytes[i], _selectedImagesNames[i]);
      if (downloadUrl != null) imageUrls.add(downloadUrl);

      if (!kIsWeb) {
        final localPath = await _savePoImageToFolder(_selectedImagesBytes[i], _selectedImagesNames[i]);
        if (localPath != null) localPaths.add(localPath);
      }
    }

    final Map<String, dynamic> poData = {
      "po_no": poNoController.text.toUpperCase(),
      "customer_name": poNameController.text,
      "quantity": poQtyController.text,
      "contact_person": poRefController.text,
      "contact_number": poContactController.text.toUpperCase(),
      "email": poEmailController.text,
      "bag_length": poBagLengthController.text,
      "bag_width": poBagWidthController.text,
      "bag_height": poBagHeightController.text,
      "swl": swl.text,
      "safety_factor": safetyFactor.text,
      "construction_style": constructionStyle.text,
      "bag_color": poBagColorController.text,
      "other_tech_spec": otherTechSpecification.text,
      "po_image": imageUrls.isNotEmpty ? imageUrls.first : "",
      "po_images": imageUrls,
      "local_images": localPaths,
      "entry_time": FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection("fibc_po").add(poData);
      if (mounted) {
        _showSnack("Data has been saved successfully.", ERPTheme.updateGreen);
        _clearForm();
      }
    } catch (e) {
      if (mounted) _showSnack('Failed to save data: $e', ERPTheme.deleteRed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    setState(() {
      poNoController.clear();
      poQtyController.clear();
      poNameController.clear();
      poRefController.clear();
      poContactController.clear();
      poEmailController.clear();
      poBagLengthController.clear();
      poBagWidthController.clear();
      poBagHeightController.clear();
      swl.clear();
      safetyFactor.clear();
      constructionStyle.clear();
      poBagColorController.clear();
      otherTechSpecification.clear();
      _selectedImagesBytes.clear();
      _selectedImagesNames.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ERPTheme.backgroundBg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(),
                Expanded(
                  child: Stack(
                    children: [
                      _isLoadingData
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildGeneralInfoCard(),
                                  const SizedBox(height: 16),
                                  _buildBagSpecsCard(),
                                  const SizedBox(height: 16),
                                  _buildTechSpecsCard(),
                                  const SizedBox(height: 16),
                                  _buildAttachmentsCard(),
                                  const SizedBox(height: 20),
                                  _buildActionButtons(),
                                ],
                              ),
                            ),
                      if (_isSubmitting)
                        Container(
                          color: Colors.black.withOpacity(0.15),
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI BUILDERS ---

  Widget _buildTopHeader() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: ERPTheme.headerNavy,
      child: Row(
        children: [
          const Text(
            'FIBC ERP',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Spacer(),
          const Text(
            'New Purchase Order',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const Spacer(),
          const Icon(Icons.account_circle, color: Colors.white, size: 22),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: ERPTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ERPTheme.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: ERPTheme.accentBlue),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: ERPTheme.textDark),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    return _buildSectionCard(
      title: 'General Information',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAutocompleteField(
                  'PO Number *', 
                  poNoController, 
                  poNos.toList(), 
                  uppercase: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAutocompleteField('Customer Name *', poNameController, customerNames.toList()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAutocompleteField('Contact Person', poRefController, contactPersons.toList()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAutocompleteField('Contact Number', poContactController, contactNumbers.toList()),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAutocompleteField(
                  'Email Address', 
                  poEmailController, 
                  emails.toList(),
                  focusNode: _emailFocusNode
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()), // Alignment Spacer
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBagSpecsCard() {
    return _buildSectionCard(
      title: 'Bag Specifications',
      icon: Icons.straighten_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildAutocompleteField('Bag Length', poBagLengthController, bagLengths.toList(), isNumeric: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildAutocompleteField('Bag Width', poBagWidthController, bagWidths.toList(), isNumeric: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildAutocompleteField('Bag Height', poBagHeightController, bagHeights.toList(), isNumeric: true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildAutocompleteField('Bag Color', poBagColorController, bagColors.toList())),
              const SizedBox(width: 12),
              Expanded(child: _buildAutocompleteField('Construction Style', constructionStyle, constructionStyles.toList())),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechSpecsCard() {
    return _buildSectionCard(
      title: 'Technical Specifications',
      icon: Icons.settings_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildAutocompleteField('Total Quantity (Pcs) *', poQtyController, quantities.toList(), isNumeric: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildAutocompleteField('SWL', swl, swls.toList())),
              const SizedBox(width: 12),
              Expanded(child: _buildAutocompleteField('Safety Factor', safetyFactor, safetyFactors.toList())),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField('Other Technical Specifications', otherTechSpecification, maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard() {
    return _buildSectionCard(
      title: 'Attachments',
      icon: Icons.attach_file_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: _pickPoImages,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
            label: const Text('Select / Add PO Images'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ERPTheme.primaryNavy,
              side: const BorderSide(color: ERPTheme.cardBorder),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          if (_selectedImagesBytes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(_selectedImagesBytes.length, (index) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: ERPTheme.cardBorder),
                        image: DecorationImage(
                          image: MemoryImage(_selectedImagesBytes[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedImagesBytes.removeAt(index);
                            _selectedImagesNames.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: ERPTheme.deleteRed,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: ERPTheme.saveBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _isSubmitting ? null : _saveDataToFirebase,
            icon: const Icon(Icons.save, size: 16),
            label: const Text('SAVE PURCHASE ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: ERPTheme.clearOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: _clearForm,
            icon: const Icon(Icons.cleaning_services, size: 16),
            label: const Text('CLEAR FORM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets for Form Fields ---

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ERPTheme.textMuted)),
        const SizedBox(height: 4),
        SizedBox(
          height: maxLines > 1 ? null : 38,
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            maxLines: maxLines,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: readOnly ? ERPTheme.textMuted : ERPTheme.textDark),
            decoration: _inputDecoration(),
          ),
        ),
      ],
    );
  }

  Widget _buildAutocompleteField(String label, TextEditingController controller, List<String> suggestions, {bool uppercase = false, bool isNumeric = false, FocusNode? focusNode}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ERPTheme.textMuted)),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
              return suggestions.where((String option) => option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (String selection) {
              controller.text = uppercase ? selection.toUpperCase() : selection;
            },
            fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
              
              // Sync logic
              if (textEditingController.text != controller.text) {
                textEditingController.text = controller.text;
              }
              controller.addListener(() {
                if (textEditingController.text != controller.text) {
                  textEditingController.text = controller.text;
                }
              });

              return TextField(
                controller: textEditingController,
                focusNode: focusNode ?? fieldFocusNode,
                keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
                inputFormatters: isNumeric ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-]'))] : null,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ERPTheme.textDark),
                decoration: _inputDecoration(),
                onChanged: (val) {
                  controller.text = uppercase ? val.toUpperCase() : val;
                },
              );
            },
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: ERPTheme.cardBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: ERPTheme.cardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: ERPTheme.accentBlue)),
    );
  }
}