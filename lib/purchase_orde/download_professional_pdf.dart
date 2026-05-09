import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> downloadProfessionalPO() async {
  
// 🔥 ADD THESE INSIDE YOUR STATE CLASS

final orderNo = TextEditingController();

final department = TextEditingController();

final partyName = TextEditingController();

final gstin = TextEditingController();

final mobile = TextEditingController();

final partyOrderNo = TextEditingController();

final forController = TextEditingController();

final payment = TextEditingController();

final freightCharges = TextEditingController();

final packingCharges = TextEditingController();

final delivery = TextEditingController();

final termsConditions = TextEditingController();

DateTime selectedDate = DateTime.now();


// 🔥 ITEMS LIST

List<Map<String, dynamic>> items = [
  {
    "description": TextEditingController(),
    "hsn": TextEditingController(),
    "qty": TextEditingController(),
    "unit": TextEditingController(),
    "rate": TextEditingController(),
    "cgst": TextEditingController(),
    "sgst": TextEditingController(),
    "igst": TextEditingController(),
    "amount": TextEditingController(),
    "remark": TextEditingController(),
  }
];


// 🔥 TOTAL FUNCTION

double getTotalAmount() {
  double total = 0;

  for (var item in items) {
    total +=
        double.tryParse(item['amount'].text) ?? 0;
  }

  return total;
}

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(18),

      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            // =====================================================
            // 🔹 COMPANY HEADER
            // =====================================================

            pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1),
              ),
              padding: const pw.EdgeInsets.all(8),

              child: pw.Column(
                children: [

                  pw.Text(
                    "KULVIR TEXTILE PRIVATE LIMITED",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),

                  pw.SizedBox(height: 4),

                  pw.Text(
                    "918-919, NANAK PURA, Rampuriya Payra Bus Stop",
                    style: const pw.TextStyle(fontSize: 9),
                  ),

                  pw.Text(
                    "MANDAL, Neem Ka Khera, Bhilwara - 311403",
                    style: const pw.TextStyle(fontSize: 9),
                  ),

                  pw.Text(
                    "GSTIN : 08AAICK1451A1ZZ",
                    style: const pw.TextStyle(fontSize: 9),
                  ),

                  pw.SizedBox(height: 6),

                  pw.Text(
                    "PURCHASE ORDER",
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // =====================================================
            // 🔹 PARTY + ORDER INFO
            // =====================================================

            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                // LEFT SIDE
                pw.Expanded(
                  flex: 3,
                  child: pw.Container(
                    height: 130,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),

                    padding: const pw.EdgeInsets.all(6),

                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [

                        pw.Text(
                          "To",
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 9,
                          ),
                        ),

                        pw.SizedBox(height: 3),

                        pw.Text(
                          partyName.text,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),

                        pw.SizedBox(height: 5),

                        pw.Text(
                          department.text,
                          style: const pw.TextStyle(fontSize: 9),
                        ),

                        pw.SizedBox(height: 5),

                        pw.Text(
                          "GSTIN : ${gstin.text}",
                          style: const pw.TextStyle(fontSize: 9),
                        ),

                        pw.SizedBox(height: 5),

                        pw.Text(
                          "Mobile : ${mobile.text}",
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),

                // RIGHT SIDE
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    height: 130,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    ),

                    padding: const pw.EdgeInsets.all(6),

                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [

                        buildInfoRow(
                          "Order No",
                          orderNo.text,
                        ),

                        buildInfoRow(
                          "Order Date",
                          "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                        ),

                        buildInfoRow(
                          "Party Order No",
                          partyOrderNo.text,
                        ),

                        buildInfoRow(
                          "FoR",
                          forController.text,
                        ),

                        buildInfoRow(
                          "Payment",
                          payment.text,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // =====================================================
            // 🔹 TABLE
            // =====================================================

            pw.Table(
              border: pw.TableBorder.all(width: 0.6),

              columnWidths: {
                0: const pw.FixedColumnWidth(25),
                1: const pw.FixedColumnWidth(120),
                2: const pw.FixedColumnWidth(45),
                3: const pw.FixedColumnWidth(40),
                4: const pw.FixedColumnWidth(35),
                5: const pw.FixedColumnWidth(45),
                6: const pw.FixedColumnWidth(35),
                7: const pw.FixedColumnWidth(35),
                8: const pw.FixedColumnWidth(35),
                9: const pw.FixedColumnWidth(55),
                10: const pw.FixedColumnWidth(60),
              },

              children: [

                // 🔹 HEADER
                pw.TableRow(
                  children: [
                    tableHeader("Sr"),
                    tableHeader("Material Description"),
                    tableHeader("HSN"),
                    tableHeader("Qty"),
                    tableHeader("Unit"),
                    tableHeader("Rate"),
                    tableHeader("CGST"),
                    tableHeader("SGST"),
                    tableHeader("IGST"),
                    tableHeader("Amount"),
                    tableHeader("Remark"),
                  ],
                ),

                // 🔹 ITEMS
                ...List.generate(items.length, (index) {

                  var item = items[index];

                  return pw.TableRow(
                    children: [

                      tableCell("${index + 1}"),

                      tableCell(
                        item['description'].text,
                      ),

                      tableCell(
                        item['hsn'].text,
                      ),

                      tableCell(
                        item['qty'].text,
                      ),

                      tableCell(
                        item['unit'].text,
                      ),

                      tableCell(
                        item['rate'].text,
                      ),

                      tableCell(
                        item['cgst'].text,
                      ),

                      tableCell(
                        item['sgst'].text,
                      ),

                      tableCell(
                        item['igst'].text,
                      ),

                      tableCell(
                        item['amount'].text,
                      ),

                      tableCell(
                        item['remark'].text,
                      ),
                    ],
                  );
                }),
              ],
            ),

            // =====================================================
            // 🔹 TOTAL
            // =====================================================

            pw.Container(
              alignment: pw.Alignment.centerRight,

              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1),
              ),

              padding: const pw.EdgeInsets.all(6),

              child: pw.Text(
                "TOTAL : Rs ${getTotalAmount().toStringAsFixed(2)}",

                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),

            // =====================================================
            // 🔹 TERMS
            // =====================================================

            pw.Container(
              width: double.infinity,

              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 1),
              ),

              padding: const pw.EdgeInsets.all(8),

              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,

                children: [

                  pw.Text(
                    "Terms & Conditions",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),

                  pw.SizedBox(height: 5),

                  pw.Text(
                    termsConditions.text,
                    style: const pw.TextStyle(fontSize: 9),
                  ),

                  pw.SizedBox(height: 5),

                  pw.Text(
                    "Freight Charges : ${freightCharges.text}",
                    style: const pw.TextStyle(fontSize: 9),
                  ),

                  pw.Text(
                    "Packing Charges : ${packingCharges.text}",
                    style: const pw.TextStyle(fontSize: 9),
                  ),

                  pw.Text(
                    "Delivery : ${delivery.text}",
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),

            pw.Spacer(),

            // =====================================================
            // 🔹 FOOTER
            // =====================================================

            pw.Row(
              mainAxisAlignment:
                  pw.MainAxisAlignment.spaceBetween,

              children: [

                pw.Text(
                  "Prepared By",
                  style: const pw.TextStyle(fontSize: 9),
                ),

                pw.Text(
                  "Checked By",
                  style: const pw.TextStyle(fontSize: 9),
                ),

                pw.Text(
                  "Authorized Sign",
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  Uint8List bytes = await pdf.save();

  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute("download", "purchase_order.pdf")
    ..click();

  html.Url.revokeObjectUrl(url);
}

// =====================================================
// 🔹 HELPERS
// =====================================================

pw.Widget buildInfoRow(
  String title,
  String value,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),

    child: pw.Row(
      children: [

        pw.Text(
          "$title : ",
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
          ),
        ),

        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    ),
  );
}

pw.Widget tableHeader(String text) {
  return pw.Container(
    alignment: pw.Alignment.center,

    padding: const pw.EdgeInsets.all(4),

    child: pw.Text(
      text,

      textAlign: pw.TextAlign.center,

      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 8,
      ),
    ),
  );
}

pw.Widget tableCell(String text) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(4),

    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 8),
    ),
  );
}