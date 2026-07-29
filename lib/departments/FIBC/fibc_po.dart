import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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
  final TextEditingController poNoController =
      TextEditingController(); // Manual PO Number
  final TextEditingController poEmailController = TextEditingController();
  final TextEditingController poBagLengthController = TextEditingController();
  final List<Uint8List> _selectedImagesBytes = [];
  final List<String> _selectedImagesNames = [];
  final TextEditingController poBagWidthController = TextEditingController();
  final TextEditingController poBagHeightController = TextEditingController();
  final TextEditingController poBagColorController = TextEditingController();
  final TextEditingController otherTechSpecification = TextEditingController();
  final TextEditingController safetyFactor = TextEditingController();
  final TextEditingController swl = TextEditingController();
  final TextEditingController constructionStyle = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isSubmitting = false;
  bool _isLoadingData = true;

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
  Set<String> safetyFactors = {
    "2 : 1",
    "3 : 1",
    "4 : 1",
    "5 : 1",
    "6 : 1",
    "7 : 1",
    "8 : 1"
  };
  Set<String> constructionStyles = {};
  Set<String> bagColors = {};
  Set<String> otherSpecs = {};

  @override
  void initState() {
    super.initState();
    _fetchUniqueData();
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        if (!poEmailController.text.contains('@') ||
            !poEmailController.text.contains('.')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    "Please enter a valid email address containing '@' and '.'"),
                backgroundColor: Colors.red.shade600,
              ),
            );
          }
          _emailFocusNode.requestFocus();
        }
      }
    });
  }

  Future<void> _fetchUniqueData() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection("fibc_po").get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data["po_no"] != null && data["po_no"].toString().isNotEmpty) {
          poNos.add(data["po_no"].toString());
        }
        if (data["customer_name"] != null &&
            data["customer_name"].toString().isNotEmpty) {
          customerNames.add(data["customer_name"].toString());
        }
        if (data["quantity"] != null &&
            data["quantity"].toString().isNotEmpty) {
          quantities.add(data["quantity"].toString());
        }
        if (data["contact_person"] != null &&
            data["contact_person"].toString().isNotEmpty) {
          contactPersons.add(data["contact_person"].toString());
        }
        if (data["contact_number"] != null &&
            data["contact_number"].toString().isNotEmpty) {
          contactNumbers.add(data["contact_number"].toString());
        }
        if (data["email"] != null && data["email"].toString().isNotEmpty) {
          emails.add(data["email"].toString());
        }
        if (data["bag_length"] != null &&
            data["bag_length"].toString().isNotEmpty) {
          bagLengths.add(data["bag_length"].toString());
        }
        if (data["bag_width"] != null &&
            data["bag_width"].toString().isNotEmpty) {
          bagWidths.add(data["bag_width"].toString());
        }
        if (data["bag_height"] != null &&
            data["bag_height"].toString().isNotEmpty) {
          bagHeights.add(data["bag_height"].toString());
        }
        if (data["swl"] != null && data["swl"].toString().isNotEmpty) {
          swls.add(data["swl"].toString());
        }
        if (data["safety_factor"] != null &&
            data["safety_factor"].toString().isNotEmpty) {
          safetyFactors.add(data["safety_factor"].toString());
        }
        if (data["construction_style"] != null &&
            data["construction_style"].toString().isNotEmpty) {
          constructionStyles.add(data["construction_style"].toString());
        }
        if (data["bag_color"] != null &&
            data["bag_color"].toString().isNotEmpty) {
          bagColors.add(data["bag_color"].toString());
        }
        if (data["other_tech_spec"] != null &&
            data["other_tech_spec"].toString().isNotEmpty) {
          otherSpecs.add(data["other_tech_spec"].toString());
        }
      }
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    super.dispose();
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error picking images: $e"),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save image: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      return null;
    }
  }

  Future<String?> _uploadPoImageToStorage(Uint8List bytes, String fileName) async {
    try {
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final ref = FirebaseStorage.instance
          .ref()
          .child('fibc_po_images/$uniqueName');
      await ref.putData(bytes).timeout(const Duration(seconds: 15));
      return await ref.getDownloadURL().timeout(const Duration(seconds: 15));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image to storage: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _saveDataToFirebase() async {
    if (!poEmailController.text.contains('@') ||
        !poEmailController.text.contains('.')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please enter a valid email address."),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      _emailFocusNode.requestFocus();
      return;
    }

    if (poNoController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please enter a PO Number."),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final List<String> imageUrls = [];
    final List<String> localPaths = [];
    for (int i = 0; i < _selectedImagesBytes.length; i++) {
      // 1. Upload to Firebase Storage
      final downloadUrl = await _uploadPoImageToStorage(
        _selectedImagesBytes[i],
        _selectedImagesNames[i],
      );
      if (downloadUrl != null) {
        imageUrls.add(downloadUrl);
      }

      // 2. Save locally if running on a desktop/mobile platform (not Web)
      if (!kIsWeb) {
        final localPath = await _savePoImageToFolder(
          _selectedImagesBytes[i],
          _selectedImagesNames[i],
        );
        if (localPath != null) {
          localPaths.add(localPath);
        }
      }
    }

    final Map<String, dynamic> poData = {
      "po_no": poNoController.text.toUpperCase(), // Manual entry
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Data has been saved successfully."),
            backgroundColor: Colors.green.shade600,
          ),
        );
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save data: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double formMaxWidth = 1000.0;
    final double formWidth =
        screenWidth < formMaxWidth ? screenWidth * 0.9 : formMaxWidth;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text(
          "Kulvir Textile Private Limited",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: _isLoadingData
            ? const CircularProgressIndicator(color: Colors.blue)
            : Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                width: formWidth,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag,
                            color: Colors.blue,
                            size: 40,
                          ),
                          SizedBox(width: 10),
                          Text(
                            "FIBC Purchase Order",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildTextField(
                        controller: poNoController,
                        label: "PO Number *",
                        icon: Icons.receipt_long,
                        isNumeric: false,
                        autofocus: true,
                        onChanged: (value) {},
                        suggestions: poNos.toList(),
                        onSuggestionSelected: (suggestion) {
                          setState(() {
                            poNoController.text = suggestion.toUpperCase();
                          });
                        },
                        inputFormatters: [
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            return TextEditingValue(
                              text: newValue.text.toUpperCase(),
                              selection: newValue.selection,
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: poNameController,
                        label: "Customer Name *",
                        icon: Icons.person,
                        onChanged: (value) {},
                        suggestions: customerNames.toList(),
                        onSuggestionSelected: (suggestion) {
                          setState(() {
                            poNameController.text = suggestion;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: poRefController,
                        label: "Contact Person (Name) *",
                        icon: Icons.person_outline,
                        onChanged: (value) {},
                        suggestions: contactPersons.toList(),
                        onSuggestionSelected: (suggestion) {
                          setState(() {
                            poRefController.text = suggestion;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: poContactController,
                        label: "Contact Number *",
                        icon: Icons.phone,
                        isNumeric: false,
                        onChanged: (value) {},
                        suggestions: contactNumbers.toList(),
                        onSuggestionSelected: (suggestion) {
                          setState(() {
                            poContactController.text = suggestion.toUpperCase();
                          });
                        },
                        inputFormatters: [
                          TextInputFormatter.withFunction((oldValue, newValue) {
                            return TextEditingValue(
                              text: newValue.text.toUpperCase(),
                              selection: newValue.selection,
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: poEmailController,
                        label: "Email Address *",
                        icon: Icons.email,
                        onChanged: (value) {},
                        suggestions: emails.toList(),
                        onSuggestionSelected: (suggestion) {
                          setState(() {
                            poEmailController.text = suggestion;
                          });
                        },
                        focusNode: _emailFocusNode,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.collections,
                                    color: Colors.blue),
                                const SizedBox(width: 8),
                                const Text(
                                  "PO Images (Optional)",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const Spacer(),
                                if (_selectedImagesBytes.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${_selectedImagesBytes.length} Selected",
                                      style: TextStyle(
                                        color: Colors.blue.shade800,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _pickPoImages,
                                icon: const Icon(
                                    Icons.add_photo_alternate_outlined),
                                label: const Text("Select / Add PO Images"),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  side: BorderSide(color: Colors.blue.shade300),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            if (_selectedImagesBytes.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: List.generate(
                                    _selectedImagesBytes.length, (index) {
                                  return Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: 140,
                                        height: 140,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey.shade300),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.05),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          child: Image.memory(
                                            _selectedImagesBytes[index],
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
                                              _selectedImagesBytes
                                                  .removeAt(index);
                                              _selectedImagesNames
                                                  .removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.6),
                                            borderRadius:
                                                const BorderRadius.only(
                                              bottomLeft: Radius.circular(8),
                                              bottomRight: Radius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            _selectedImagesNames[index],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ] else ...[
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  "No images selected yet. Please upload at least one image.",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: poBagLengthController,
                              label: "Length",
                              icon: Icons.straighten,
                              isNumeric: true,
                              suggestions: bagLengths.toList(),
                              onSuggestionSelected: (val) {
                                setState(() {
                                  poBagLengthController.text = val;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: poBagWidthController,
                              label: "Width",
                              icon: Icons.straighten,
                              isNumeric: true,
                              suggestions: bagWidths.toList(),
                              onSuggestionSelected: (val) {
                                setState(() {
                                  poBagWidthController.text = val;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: poBagHeightController,
                              label: "Height",
                              icon: Icons.height,
                              isNumeric: true,
                              suggestions: bagHeights.toList(),
                              onSuggestionSelected: (val) {
                                setState(() {
                                  poBagHeightController.text = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: poQtyController,
                        label: "Total Quantity (Pcs) *",
                        icon: Icons.format_list_numbered,
                        isNumeric: true,
                        onChanged: (value) {},
                        suggestions: quantities.toList(),
                        onSuggestionSelected: (suggestion) {
                          setState(() {
                            poQtyController.text = suggestion;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: swl,
                        label: "SWL",
                        icon: Icons.monitor_weight,
                        suggestions: swls.toList(),
                        onSuggestionSelected: (val) {
                          setState(() {
                            swl.text = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: safetyFactor,
                        label: "Safety Factor",
                        icon: Icons.health_and_safety,
                        suggestions: safetyFactors.toList(),
                        onSuggestionSelected: (val) {
                          setState(() {
                            safetyFactor.text = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: constructionStyle,
                        label: "Construction Style",
                        icon: Icons.architecture,
                        suggestions: constructionStyles.toList(),
                        onSuggestionSelected: (val) {
                          setState(() {
                            constructionStyle.text = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: poBagColorController,
                        label: "Bag Color",
                        icon: Icons.color_lens,
                        suggestions: bagColors.toList(),
                        onSuggestionSelected: (val) {
                          setState(() {
                            poBagColorController.text = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: otherTechSpecification,
                        label: "Other Technical Specifications",
                        icon: Icons.description,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _saveDataToFirebase,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Save Purchase Order",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumeric = false,
    bool autofocus = false,
    Function(String)? onChanged,
    List<String>? suggestions,
    Function(String)? onSuggestionSelected,
    FocusNode? focusNode,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final bool hasSuggestions = suggestions != null && suggestions.isNotEmpty;

    Widget buildField(BuildContext context,
        TextEditingController fieldController, FocusNode fieldFocusNode) {
      return TextField(
        controller: fieldController,
        focusNode: fieldFocusNode,
        autofocus: autofocus,
        maxLines: maxLines,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        inputFormatters: inputFormatters ??
            (isNumeric
                ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-]'))]
                : null),
        onChanged: (value) {
          if (fieldController != controller) {
            controller.text = value;
          }
          if (onChanged != null) onChanged(value);
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      );
    }

    if (hasSuggestions) {
      return Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          return suggestions.where((String option) {
            return option
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase());
          });
        },
        onSelected: (String selection) {
          controller.text = selection;
          if (onSuggestionSelected != null) onSuggestionSelected(selection);
          if (onChanged != null) onChanged(selection);
        },
        fieldViewBuilder: (BuildContext context,
            TextEditingController textEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted) {
          // Sync controllers if needed
          if (textEditingController.text != controller.text) {
            textEditingController.text = controller.text;
          }
          controller.addListener(() {
            if (textEditingController.text != controller.text) {
              textEditingController.text = controller.text;
            }
          });
          return buildField(
              context, textEditingController, focusNode ?? fieldFocusNode);
        },
      );
    } else {
      return buildField(context, controller, focusNode ?? FocusNode());
    }
  }
}
