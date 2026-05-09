import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
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

  DateTime selectedDate = DateTime.now();

  // 🔹 ITEMS
  List<Map<String, dynamic>> items = [];

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

  Future<void> downloadPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // 🔹 TITLE
          pw.Center(
            child: pw.Text(
              "PURCHASE ORDER",
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(height: 20),

          // 🔹 HEADER DETAILS
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("Order No : ${orderNo.text}"),
                  pw.Text(
                    "Date : ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                  ),
                  pw.Text("Department : ${department.text}"),
                  pw.Text("Party Name : ${partyName.text}"),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text("FoR : ${forController.text}"),
                  pw.Text("Payment : ${payment.text}"),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // 🔹 TABLE
          pw.Table.fromTextArray(
            border: pw.TableBorder.all(),
            headers: [
              "S.No",
              "Description",
              "HSN",
              "Qty",
              "Unit",
              "Rate",
              "CGST",
              "SGST",
              "IGST",
              "Amount",
            ],
            data: List.generate(items.length, (index) {
              var item = items[index];

              return [
                "${index + 1}",
                item['description'].text,
                item['hsn'].text,
                item['qty'].text,
                item['unit'].text,
                item['rate'].text,
                item['cgst'].text,
                item['sgst'].text,
                item['igst'].text,
                item['amount'].text,
              ];
            }),
          ),

          pw.SizedBox(height: 20),

          // 🔹 TOTAL
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Total Amount : Rs ${getTotalAmount().toStringAsFixed(2)}",
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(height: 20),

          // 🔹 TERMS
          pw.Text(
            "Terms & Conditions",
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 8),

          pw.Text(termsConditions.text),

          pw.SizedBox(height: 20),

          // 🔹 FOOTER
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("Prepared By"),
              pw.Text("Checked By"),
              pw.Text("Authorized Sign"),
            ],
          ),
        ],
      ),
    );

    Uint8List bytes = await pdf.save();

    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
    );
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
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Purchase Order Saved")),
    );
  }

  @override
  void initState() {
    super.initState();
    addItemRow();
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
                    TextField(
                      controller: orderNo,
                      decoration: const InputDecoration(
                        labelText: "Order No (Auto Increase)",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: department,
                      decoration: const InputDecoration(
                        labelText: "Department",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: partyName,
                      decoration: const InputDecoration(
                        labelText: "Party Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: termsConditions,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Terms & Conditions",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 ORDER DETAILS
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Order Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: orderNo,
                            decoration: const InputDecoration(
                              labelText: "Order No",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              var picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );

                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            child: Text(
                              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: partyOrderNo,
                      decoration: const InputDecoration(
                        labelText: "Party Order No",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remarks,
                      decoration: const InputDecoration(
                        labelText: "Remarks",
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
                  "Total Amount : ₹ ${getTotalAmount().toStringAsFixed(2)}",
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

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: downloadPdf,
                icon: const Icon(Icons.download,color: Colors.white,),
                label: const Text("Download PDF"),
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
