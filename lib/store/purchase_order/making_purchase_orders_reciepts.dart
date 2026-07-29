import 'package:app/store/purchase_order/download_professional_pdf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {

  List<String> departmentOptions = [];

  // 🔹 HEADER CONTROLLERS
  
  final orderNo = TextEditingController();
  final department = TextEditingController();
  final partyName = TextEditingController();

  // 🔹 TERMS & CONDITIONS
  final termsConditions = TextEditingController();
  final forController = TextEditingController();
  final freightCharges = TextEditingController();
  final packingCharges = TextEditingController();
  final payment = TextEditingController();
  final delivery = TextEditingController();
  final partyOrderNo = TextEditingController();
  final remarks = TextEditingController();

  final addressController = TextEditingController();
final mobileController = TextEditingController();
final emailController = TextEditingController();
final gstinController = TextEditingController();
final stateController = TextEditingController();
final statusController = TextEditingController();

final amountInWordsController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> items = [];
  Map<String, Map<String, dynamic>> partyDataMap = {}; 
  List<String> partyOptions = [];

  Future<void> fetchDepartments() async {
  final snapshot = await FirebaseFirestore.instance.collection("departments").get();
  setState(() {
    departmentOptions = snapshot.docs.map((doc) => doc['name'].toString()).toList();
  });
}

  void addItemRow() {
    setState(() {
      items.add({
        "description": TextEditingController(),
        "hsn": TextEditingController(),
        "qty": TextEditingController(),
        "unit": TextEditingController(),
        "rate": TextEditingController(),
        "discount_including_gst": TextEditingController(),
        "discount_excluding_gst": TextEditingController(),
        "cgst": TextEditingController(),
        "sgst": TextEditingController(),
        "igst": TextEditingController(),
        "amount": TextEditingController(),
        "remark": TextEditingController(),
      });
    });
  }

  double getTotalAmount() {
    double total = 0;

    for (var item in items) {
      total += double.tryParse(item['amount'].text) ?? 0;
    }

    return total;
  }

  Future<void> savePurchaseOrder() async {
    List<Map<String, dynamic>> finalItems = [];

    for (var item in items) {
      finalItems.add({
        "description": item['description'].text,
        "hsn_sac_code": item['hsn'].text,
        "qty": double.tryParse(item['qty'].text) ?? 0,
        "unit": item['unit'].text,
        "rate": double.tryParse(item['rate'].text) ?? 0,
        "discount_including_gst":
            double.tryParse(item['discount_including_gst'].text) ?? 0,
        "discount_excluding_gst":
            double.tryParse(item['discount_excluding_gst'].text) ?? 0,
        "cgst": double.tryParse(item['cgst'].text) ?? 0,
        "sgst": double.tryParse(item['sgst'].text) ?? 0,
        "igst": double.tryParse(item['igst'].text) ?? 0,
        "amount": double.tryParse(item['amount'].text) ?? 0,
        "remark": item['remark'].text,
      });
    }

    await FirebaseFirestore.instance.collection("purchase_orders").add({
      "order_no": orderNo.text,
      "department": department.text,
      "party_name": partyName.text,
      "order_date": Timestamp.fromDate(selectedDate),
      "terms_conditions": termsConditions.text,
      "for": forController.text,
      "freight_charges": freightCharges.text,
      "packing_charges": packingCharges.text,
      "payment": payment.text,
      "delivery": delivery.text,
      "items": finalItems,
      "total_amount": getTotalAmount(),
      "created_at": FieldValue.serverTimestamp(),
      "address": addressController.text,
"mobile": mobileController.text,
"email": emailController.text,
"gstin": gstinController.text,
"state": stateController.text,
"status": statusController.text,
"amount_in_words": amountInWordsController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Purchase Order Saved")),
    );
  }

  Future<void> fetchParties() async {
  final snapshot = await FirebaseFirestore.instance.collection("party_master").get();
  
  Map<String, Map<String, dynamic>> tempMap = {};
  for (var doc in snapshot.docs) {
    var data = doc.data();
    String name = data['Vendor_Name']?.toString() ?? "Unknown";
    tempMap[name] = data; // Store the whole object
  }
  
  setState(() {
    partyDataMap = tempMap;
    partyOptions = tempMap.keys.toList();
  });
}

  @override
  void initState() {
    super.initState();
    addItemRow();
    generateOrderNumber();
    fetchDepartments();
    fetchParties();

    termsConditions.text = 
      "* PAYMENT-30 DAYS\n"
      "* FRIGHT CHARGE-BHILWARA\n"
      "* F.O.R.BHILWARA";
  }

  Future<void> generateOrderNumber() async {

  var snapshot = await FirebaseFirestore.instance
      .collection("purchase_orders")
      .orderBy("order_no", descending: true)
      .limit(1)
      .get();

  int nextOrderNo = 1001; // Default starting number

  if (snapshot.docs.isNotEmpty) {
    int lastOrderNo = int.tryParse(snapshot.docs.first['order_no'].toString()) ?? 1000;
    nextOrderNo = lastOrderNo + 1;
  }

  setState(() {
    orderNo.text = nextOrderNo.toString();
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase Order"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 VENDOR DETAILS
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Purchase Order Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
Text(
  "Order No: ${orderNo.text.isEmpty ? 'Loading...' : orderNo.text}",
  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
),
                    const SizedBox(height: 12),
                    Autocomplete<String>(
  optionsBuilder: (TextEditingValue textEditingValue) {
    if (textEditingValue.text.isEmpty) {
      return departmentOptions;
    }
    return departmentOptions.where((String option) {
      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
    });
  },
  onSelected: (String selection) {
    department.text = selection; // Autofill the controller
  },
  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
    // Sync the local controller with the widget's controller
    controller.text = department.text; 
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: const InputDecoration(
        labelText: "Department",
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.arrow_drop_down),
      ),
      onChanged: (val) => department.text = val,
    );
  },
),
                    const SizedBox(height: 12),
                    Autocomplete<String>(
  optionsBuilder: (TextEditingValue textEditingValue) {
    if (textEditingValue.text.isEmpty) return partyOptions;
    return partyOptions.where((String option) =>
        option.toLowerCase().contains(textEditingValue.text.toLowerCase()));
  },
  onSelected: (String selection) {
    partyName.text = selection;
    
    // Autofill additional fields based on selected party
    var data = partyDataMap[selection];
    if (data != null) {
      setState(() {
        addressController.text = "${data['Address'] ?? ''} ${data['Address2'] ?? ''}";
        gstinController.text = data['GST']?.toString() ?? '';
        emailController.text = data['email']?.toString() ?? '';
      });
    }
  },
  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
    controller.text = partyName.text;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: const InputDecoration(
        labelText: "Party Name",
        border: OutlineInputBorder(),
        suffixIcon: Icon(Icons.search),
      ),
      onChanged: (val) => partyName.text = val,
    );
  },
),
                    const SizedBox(height: 12),
                    
TextField(
  controller: addressController,
  maxLines: 2,
  decoration: const InputDecoration(
    labelText: "Party Address",
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 12),

TextField(
  controller: mobileController,
  keyboardType: TextInputType.phone,
  decoration: const InputDecoration(
    labelText: "Mobile Number",
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 12),

TextField(
  controller: emailController,
  keyboardType: TextInputType.emailAddress,
  decoration: const InputDecoration(
    labelText: "Email Address",
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 12),

TextField(
  controller: gstinController,
  decoration: const InputDecoration(
    labelText: "GSTIN",
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 12),

TextField(
  controller: stateController,
  decoration: const InputDecoration(
    labelText: "State",
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 12),

TextField(
  controller: statusController,
  decoration: const InputDecoration(
    labelText: "Status",
    border: OutlineInputBorder(),
  ),
),

const SizedBox(height: 12),

TextField(
  controller: amountInWordsController,
  maxLines: 2,
  decoration: const InputDecoration(
    labelText: "Amount In Words",
    hintText: "Example : Rupees Fifty Thousand Only",
    border: OutlineInputBorder(),
  ),
),


                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 ITEMS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Items",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: addItemRow,
                  icon: const Icon(Icons.add,color: Colors.white,),
                  label: const Text("Add Item"),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Description")),
                  DataColumn(label: Text("HSN")),
                  DataColumn(label: Text("Qty")),
                  DataColumn(label: Text("Unit")),
                  DataColumn(label: Text("Rate")),
                  DataColumn(label: Text("Disc % Incl GST")),
                  DataColumn(label: Text("Disc % Excl GST")),
                  DataColumn(label: Text("CGST %")),
                  DataColumn(label: Text("SGST %")),
                  DataColumn(label: Text("IGST %")),
                  DataColumn(label: Text("Amount")),
                  DataColumn(label: Text("Remark")),
                ],
                rows: items.map((item) {
                  return DataRow(
                    cells: [
                      buildCell(item['description']),
                      buildCell(item['hsn']),
                      buildCell(item['qty'], isNumber: true),
                      buildCell(item['unit']),
                      buildCell(item['rate'], isNumber: true),
                      buildCell(item['discount_including_gst'], isNumber: true),
                      buildCell(item['discount_excluding_gst'], isNumber: true),
                      buildCell(item['cgst'], isNumber: true),
                      buildCell(item['sgst'], isNumber: true),
                      buildCell(item['igst'], isNumber: true),
                      buildCell(item['amount'], isNumber: true),
                      buildCell(item['remark']),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Total Amount : Rs. ${getTotalAmount().toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const SizedBox(height: 20),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: forController,
                      decoration: const InputDecoration(
                        labelText: "FoR",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: freightCharges,
                      decoration: const InputDecoration(
                        labelText: "Freight Charges",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: packingCharges,
                      decoration: const InputDecoration(
                        labelText: "Packing Charges",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: payment,
                      decoration: const InputDecoration(
                        labelText: "Payment",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: delivery,
                      decoration: const InputDecoration(
                        labelText: "Delivery",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                onPressed: savePurchaseOrder,
                child: const Text(
                  "Save Purchase Order",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              onPressed: () async {
                // 1. Convert the items with TextEditingControllers into plain text maps
                List<Map<String, dynamic>> finalPdfItems = items.map((item) {
                  return {
                    "description": item['description'].text,
                    "hsn": item['hsn'].text,
                    "qty": item['qty'].text,
                    "unit": item['unit'].text,
                    "rate": item['rate'].text,
                    "cgst": item['cgst'].text,
                    "sgst": item['sgst'].text,
                    "igst": item['igst'].text,
                    "amount": item['amount'].text,
                    "remark": item['remark'].text,
                  };
                }).toList();

                // 2. Call your new PDF function with the exact controller values
                await downloadPurchaseOrderPdf(
  orderNo: orderNo.text,
  partyName: partyName.text,
  address: addressController.text,
  gstin: gstinController.text,
  mobile: mobileController.text,
  department: department.text,
  payment: payment.text,
  forValue: forController.text,
  terms: termsConditions.text,
  items: finalPdfItems,
  amountInWords: amountInWordsController.text,
  email: emailController.text,
state: stateController.text,
status: statusController.text,
);
              },
              child: Center(
                child: const Text(
                  "Print PDF",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataCell buildCell(
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return DataCell(
      SizedBox(
        width: 120,
        child: TextField(
          controller: controller,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
