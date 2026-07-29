import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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

class StitchingReceiveScreen extends StatefulWidget {
  const StitchingReceiveScreen({super.key});

  @override
  State<StitchingReceiveScreen> createState() => _StitchingReceiveScreenState();
}

class _StitchingReceiveScreenState extends State<StitchingReceiveScreen> {
  // Entry Information
  final TextEditingController _entryNoController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _shiftController = TextEditingController();
  final TextEditingController _operatorController = TextEditingController();

  // Order Information
  String? _selectedOrderNo;
  final TextEditingController _orderQuantityController = TextEditingController();
  final TextEditingController _bagSizeController = TextEditingController();

  // Dynamic Component Details List
  final List<StitchingComponentItem> _components = [];

  // Production Details
  final TextEditingController _finishBagQtyController = TextEditingController();
  final TextEditingController _balanceBagQtyController = TextEditingController();
  final TextEditingController _lineWasteController = TextEditingController();
  final TextEditingController _sendBagQtyController = TextEditingController();

  // Remarks
  final TextEditingController _remarksController = TextEditingController();

  // State flags
  bool _bagSendToBalling = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeDefaults();
    _addComponentRow(); // Start with 1 empty component row
  }

  void _initializeDefaults() {
    final now = DateTime.now();
    
    // Auto-Generate Unique Entry Number (Format: SR-YYYYMMDD-XXXX)
    String uniqueSuffix = now.millisecondsSinceEpoch.toString().substring(9);
    _entryNoController.text = 'SR-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$uniqueSuffix';
    
    _dateController.text = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    _timeController.text = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _shiftController.text = 'B';
    _operatorController.text = 'Sunil Verma'; // Can be fetched from logged-in user context
  }

  // --- Dynamic Component Logic ---
  void _addComponentRow() {
    setState(() {
      _components.add(StitchingComponentItem());
    });
  }

  void _removeComponentRow(int index) {
    if (_components.length > 1) {
      setState(() {
        _components.removeAt(index);
      });
    } else {
      _showSnack('At least one component row is required.', Colors.orange);
    }
  }

  // --- Firestore Logic ---
  Future<void> _fetchOrderDetails(String orderNo) async {
    if (orderNo.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('fibc_work_orders')
          .where('work_order_no', isEqualTo: orderNo)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        setState(() {
          _orderQuantityController.text = (data['quantity'] ?? '').toString();
          _bagSizeController.text = (data['bag_size'] ?? '').toString();
        });
        _showSnack('Order details fetched successfully.', Colors.green);
      }
    } catch (e) {
      _showSnack('Error fetching order details: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEntry() async {
    if (_selectedOrderNo == null || _selectedOrderNo!.isEmpty) {
      _showSnack('Please select an Order No.', Colors.orange);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Prepare Component Data
      List<Map<String, dynamic>> componentsData = _components.map((c) => c.toMap()).toList();

      // 2. Prepare Main Payload
      final stitchingData = {
        'entryNo': _entryNoController.text,
        'date': _dateController.text,
        'time': _timeController.text,
        'shift': _shiftController.text,
        'operator': _operatorController.text,
        'orderNo': _selectedOrderNo,
        'orderQuantity': int.tryParse(_orderQuantityController.text) ?? 0,
        'bagSize': _bagSizeController.text,
        'components': componentsData, // Successfully stores user-added components
        'finishBagQuantity': int.tryParse(_finishBagQtyController.text) ?? 0,
        'balanceBagQuantity': int.tryParse(_balanceBagQtyController.text) ?? 0,
        'lineWaste': double.tryParse(_lineWasteController.text) ?? 0.0,
        'bagSendToBalling': _bagSendToBalling,
        'sendBagQuantity': int.tryParse(_sendBagQtyController.text) ?? 0,
        'remarks': _remarksController.text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // 3. Save to Firestore
      await FirebaseFirestore.instance.collection('stitching_receive').add(stitchingData);

      _showSnack('Stitching Receive entry saved successfully!', ERPTheme.saveBlue);
      _clearForm();
    } catch (e) {
      _showSnack('Failed to save entry: $e', ERPTheme.deleteRed);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    setState(() {
      _selectedOrderNo = null;
      _orderQuantityController.clear();
      _bagSizeController.clear();
      _finishBagQtyController.clear();
      _balanceBagQtyController.clear();
      _lineWasteController.clear();
      _sendBagQtyController.clear();
      _remarksController.clear();
      _bagSendToBalling = false;
      _components.clear();
    });
    _initializeDefaults();
    _addComponentRow();
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg, behavior: SnackBarBehavior.floating),
    );
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
                      SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEntryInformationCard(),
                            const SizedBox(height: 16),
                            _buildOrderInformationCard(),
                            const SizedBox(height: 16),
                            _buildComponentDetailsCard(), // Updated to be dynamic
                            const SizedBox(height: 16),
                            _buildProductionDetailsCard(),
                            const SizedBox(height: 16),
                            _buildRemarksCard(),
                            const SizedBox(height: 20),
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                      if (_isLoading)
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
            '3. Stitching Receive Entry',
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

  Widget _buildEntryInformationCard() {
    return Row(
      children: [
        Expanded(child: _buildTextField('Entry No.', _entryNoController, readOnly: true, fillBackground: false)),
        const SizedBox(width: 12),
        Expanded(child: _buildTextField('Date', _dateController, fillBackground: false)),
        const SizedBox(width: 12),
        Expanded(child: _buildTextField('Time', _timeController, fillBackground: false)),
        const SizedBox(width: 12),
        Expanded(child: _buildTextField('Shift', _shiftController, fillBackground: false)),
        const SizedBox(width: 12),
        Expanded(child: _buildTextField('Operator', _operatorController, fillBackground: false)),
      ],
    );
  }

  Widget _buildOrderInformationCard() {
    return _buildSectionCard(
      title: 'Order Information',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildOrderNoDropdown()),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Order Quantity (Pcs) *', _orderQuantityController)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField('Bag Size (L x W x H) (cm) *', _bagSizeController)),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNoDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Order No. *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ERPTheme.textMuted)),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('fibc_work_orders').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }
              List<DropdownMenuItem<String>> items = [];
              if (snapshot.hasData) {
                items = snapshot.data!.docs.map((doc) {
                  final orderNo = doc['work_order_no'].toString();
                  return DropdownMenuItem<String>(
                    value: orderNo,
                    child: Text(orderNo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ERPTheme.textDark)),
                  );
                }).toList();
              }
              return DropdownButtonFormField<String>(
                value: _selectedOrderNo,
                icon: const Icon(Icons.arrow_drop_down, color: ERPTheme.textMuted, size: 20),
                decoration: _inputDecoration('Select Order No.'),
                items: items,
                onChanged: (val) {
                  setState(() => _selectedOrderNo = val);
                  if (val != null) _fetchOrderDetails(val);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildComponentDetailsCard() {
    return _buildSectionCard(
      title: 'Component Details',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          ..._components.asMap().entries.map((entry) {
            int idx = entry.key;
            StitchingComponentItem item = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ERPTheme.backgroundBg.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ERPTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Component Name', style: TextStyle(fontSize: 11, color: ERPTheme.textMuted, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          SizedBox(
                            height: 38,
                            child: DropdownButtonFormField<String>(
                              value: item.name,
                              decoration: _inputDecoration(''),
                              items: ['Body Panel', 'Top Panel', 'Bottom Panel', 'Lifting Loop', 'Baffle']
                                  .map((label) => DropdownMenuItem(value: label, child: Text(label, style: const TextStyle(fontSize: 12))))
                                  .toList(),
                              onChanged: (val) => setState(() => item.name = val ?? item.name),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField('Size (cm)', item.sizeController, onChanged: (v) => item.size = v)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField('Weight (Kg)', item.weightController, onChanged: (v) => item.weight = double.tryParse(v) ?? 0.0)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField('Quantity (Pcs)', item.qtyController, onChanged: (v) => item.quantity = int.tryParse(v) ?? 0)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildTextField('Balance Qty', item.balanceController, onChanged: (v) => item.balanceQty = int.tryParse(v) ?? 0)),
                    
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, color: ERPTheme.deleteRed, size: 20),
                        onPressed: () => _removeComponentRow(idx),
                      ),
                    )
                  ],
                ),
              ),
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _addComponentRow,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Component Row', style: TextStyle(fontSize: 12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProductionDetailsCard() {
    return _buildSectionCard(
      title: 'Production Details',
      icon: Icons.precision_manufacturing_outlined,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _buildTextField('Finish Bag Quantity (Pcs) *', _finishBagQtyController)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Balance Bag Quantity (Pcs)', _balanceBagQtyController)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextField('Line Waste (Pcs)', _lineWasteController),
                    const SizedBox(height: 4),
                    const Text('0.50 %', style: TextStyle(fontSize: 11, color: ERPTheme.textMuted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Checkbox(
                      value: _bagSendToBalling,
                      activeColor: ERPTheme.primaryNavy,
                      onChanged: (val) => setState(() => _bagSendToBalling = val ?? false),
                    ),
                    const Text('Bag Send to Balling', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField('Send Bag Quantity (Pcs)', _sendBagQtyController)),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()), 
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksCard() {
    return _buildSectionCard(
      title: 'Remarks',
      icon: Icons.chat_bubble_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Remark', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ERPTheme.textMuted)),
          const SizedBox(height: 4),
          TextField(
            controller: _remarksController,
            maxLines: 3,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ERPTheme.textDark),
            decoration: _inputDecoration(''),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        _buildActionButton('SAVE', Icons.save, ERPTheme.saveBlue, _saveEntry),
        const SizedBox(width: 12),
        _buildActionButton('UPDATE', Icons.edit, ERPTheme.updateGreen, () {}),
        const SizedBox(width: 12),
        _buildActionButton('CLEAR', Icons.cleaning_services, ERPTheme.clearOrange, _clearForm),
        const SizedBox(width: 12),
        _buildActionButton('DELETE', Icons.delete, ERPTheme.deleteRed, () {}),
        const SizedBox(width: 12),
        _buildActionButton('PRINT', Icons.print, ERPTheme.printPurple, () {}),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color bg, VoidCallback onPressed) {
    return Expanded(
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool readOnly = false, bool fillBackground = true, Function(String)? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ERPTheme.textMuted)),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onChanged: onChanged,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: readOnly && fillBackground ? ERPTheme.textMuted : ERPTheme.textDark),
            decoration: InputDecoration(
              filled: true,
              fillColor: fillBackground ? (readOnly ? const Color(0xFFF8FAFC) : Colors.white) : Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: fillBackground ? ERPTheme.cardBorder : Colors.transparent)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide(color: fillBackground ? ERPTheme.cardBorder : Colors.transparent)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: ERPTheme.accentBlue)),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: ERPTheme.cardBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: ERPTheme.cardBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: ERPTheme.accentBlue)),
    );
  }
}

// Data Model for Dynamic Stitching Components
class StitchingComponentItem {
  String name;
  String size;
  double weight;
  int quantity;
  int balanceQty;

  TextEditingController sizeController = TextEditingController();
  TextEditingController weightController = TextEditingController();
  TextEditingController qtyController = TextEditingController();
  TextEditingController balanceController = TextEditingController();

  StitchingComponentItem({
    this.name = 'Body Panel',
    this.size = '',
    this.weight = 0.0,
    this.quantity = 0,
    this.balanceQty = 0,
  });

  // This is used to bundle the object cleanly when pushing to Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'size': size,
      'weight': weight,
      'quantity': quantity,
      'balanceQty': balanceQty,
    };
  }
}