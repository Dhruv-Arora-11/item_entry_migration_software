import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> downloadPurchaseOrderPdf({
  required String orderNo,
  required String partyName,
  required String address,
  required String gstin,
  required String mobile,
  required String department,
  required String payment,
  required String forValue,
  required String terms,
  required List<Map<String, dynamic>> items,
  required String amountInWords,
  required String email,
required String state,
required String status,
}) async {

  final myFont = await PdfGoogleFonts.robotoRegular();
final myFontBold = await PdfGoogleFonts.robotoBold();

final pdf = pw.Document();  

  double totalAmount = 0;

  for (var item in items) {
    totalAmount +=
        double.tryParse(item['amount'].toString()) ?? 0;
  }

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(10),

      theme: pw.ThemeData.withFont(
      base: myFont,
      bold: myFontBold,
    ),

      build: (context) {

        return pw.Container(

          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 1),
          ),

          child: pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start,

            children: [

              // ===================================================
// HEADER EXACT FORMAT
// ===================================================

pw.Container(
  width: double.infinity,

  decoration: pw.BoxDecoration(
    border: pw.Border.all(width: 0.8),
  ),

  child: pw.Column(
    children: [

      // TOP GST + PHONE
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 3,
        ),

        child: pw.Row(
          mainAxisAlignment:
              pw.MainAxisAlignment.spaceBetween,

          children: [

            pw.Text(
              "GSTIN: 08AAICK1451A1ZZ",

              style: pw.TextStyle(
                fontWeight:
                                  pw.FontWeight.bold,
                fontSize: 8,
              ),
            ),

            pw.Text(
              "Phones:9257883555",

              style: pw.TextStyle(
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),

      // COMPANY NAME
      pw.Text(
        "KULVIR TEXTILE PRIVATE LIMITED",

        style: pw.TextStyle(
          fontSize: 15,
        
        ),
      ),

      pw.SizedBox(height: 4),

      // ADDRESS LINE 1
      pw.Text(
        "918-919, NANAK PURA, Rampuriya Payra Bus Stop",

        style: const pw.TextStyle(
          fontSize: 8,
        ),
      ),

      // ADDRESS LINE 2
      pw.Text(
        "MANDAL, Neem Ka Khera, Bhilwara-311403",

        style: const pw.TextStyle(
          fontSize: 8,
        ),
      ),

      // GST STATE LINE
      pw.Text(
        "GSTIN : 08AAICK1451A1ZZ, State : RAJASTHAN, Code : 08",

        style: const pw.TextStyle(
          fontSize: 8,
        ),
      ),

      pw.SizedBox(height: 4),

      // PURCHASE ORDER TITLE
      pw.Container(
        width: double.infinity,

        decoration: const pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(width: 0.8),
          ),
        ),

        padding: const pw.EdgeInsets.symmetric(
          vertical: 3,
        ),

        alignment: pw.Alignment.center,

        child: pw.Text(
          "PURCHASE ORDER",

          style: pw.TextStyle(
            fontSize: 10,
          
          ),
        ),
      ),
                  ],
                ),
              ),

              // ===================================================
              // TOP DETAILS
              // ===================================================

              pw.Row(
                crossAxisAlignment:
                    pw.CrossAxisAlignment.start,

                children: [

                  // LEFT
                  pw.Expanded(
                    flex: 3,

                    child: pw.Container(
                      height: 120,

                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          width: 0.5,
                        ),
                      ),

                      padding:
                          const pw.EdgeInsets.all(5),

                      child: pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment
                                .start,

                        children: [

                          pw.Text(
                            "To",
                            style: pw.TextStyle(
                              decoration: pw.TextDecoration.underline,
                              fontSize: 8,
                            ),
                          ),

                          pw.SizedBox(height: 3),

                          pw.Text(
                            partyName,

                            style: pw.TextStyle(
                              fontWeight:
                                  pw.FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),

                          pw.SizedBox(height: 5),

                          pw.Text(
                            address,
                            style:
                                const pw.TextStyle(
                              fontSize: 8,
                            ),
                          ),

                          pw.SizedBox(height: 5),

                          pw.Text(
                            "Mobile : $mobile",
                            style:
                                const pw.TextStyle(
                              fontSize: 8,
                            ),
                          ),

                          pw.Text(
                            "GSTIN : $gstin",
                            style:
                                const pw.TextStyle(
                              fontSize: 8,
                            ),
                          ),

                          pw.Text(
                            "State : RAJASTHAN",
                            style:
                                const pw.TextStyle(
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // CENTER
                  pw.Expanded(
                    flex: 3,

                    child: pw.Container(
                      height: 120,

                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          width: 0.5,
                        ),
                      ),

                      padding:
                          const pw.EdgeInsets.all(5),

                      child: pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment
                                .start,

                        children: [

                          pw.Text(
                            "Delivery And Invoice To",

                            style: pw.TextStyle(
                              decoration: pw.TextDecoration.underline,
                              fontSize: 8,
                            ),
                          ),

                          pw.SizedBox(height: 5),

                          pw.Text(
                            "KULVIR TEXTILE PRIVATE LIMITED",

                            style: pw.TextStyle(
                              fontWeight:
                                  pw.FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),

                          pw.Text(
                            "918-919 NANAK PURA",
                            style:
                                const pw.TextStyle(
                              fontSize: 8,
                            ),
                          ),

                          pw.Text(
                            "MANDAL, Bhilwara",
                            style:
                                const pw.TextStyle(
                              fontSize: 8,
                            ),
                          ),

                          pw.Text(
                            "GSTIN : 08AAICK1451A1ZZ",
                            style:
                                const pw.TextStyle(
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // RIGHT
                  pw.Expanded(
                    flex: 2,

                    child: pw.Container(
                      height: 120,

                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          width: 0.5,
                        ),
                      ),

                      padding:
                          const pw.EdgeInsets.all(5),

                      child: pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment
                                .start,

                        children: [

                          infoRow(
                            "Order No",
                            orderNo,
                          ),

                          infoRow(
                            "Order Date",
                            "04/05/2026",
                          ),

                          infoRow(
                            "Party Order No",
                            "0",
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ===================================================
              // TABLE
              // ===================================================

              pw.Container(
                height: 470,

                child: pw.Table(
                  border:
                      pw.TableBorder.all(width: 0.5),

                  columnWidths: {

                    0: const pw.FixedColumnWidth(20),
                    1: const pw.FixedColumnWidth(120),
                    2: const pw.FixedColumnWidth(45),
                    3: const pw.FixedColumnWidth(40),
                    4: const pw.FixedColumnWidth(35),
                    5: const pw.FixedColumnWidth(45),
                    6: const pw.FixedColumnWidth(35),
                    7: const pw.FixedColumnWidth(35),
                    8: const pw.FixedColumnWidth(35),
                    9: const pw.FixedColumnWidth(60),
                    10: const pw.FixedColumnWidth(50),
                  },

                  children: [

                    // HEADER
                    pw.TableRow(
                      children: [

                        tableHeader("Sr\nNo"),
                        tableHeader(
                            "Material Description"),
                        tableHeader("HSN/SAC"),
                        tableHeader("Quantity"),
                        tableHeader("UOM"),
                        tableHeader("Rate"),
                        tableHeader("CGST%"),
                        tableHeader("SGST%"),
                        tableHeader("IGST%"),
                        tableHeader("Amount"),
                        tableHeader("Remark"),
                      ],
                    ),

// ===============================
// FIXED TABLE ROWS
// ===============================

...List.generate(
  items.length,
  (index) {
    var item = items[index];

    return pw.TableRow(
      children: [
        tableCell("${index + 1}"),
        tableCell(item['description']?.toString() ?? ""),
        tableCell(item['hsn']?.toString() ?? ""),
        tableCell(item['qty']?.toString() ?? ""),
        tableCell(item['unit']?.toString() ?? ""),
        tableCell(item['rate']?.toString() ?? ""),
        tableCell(item['cgst']?.toString() ?? ""),
        tableCell(item['sgst']?.toString() ?? ""),
        tableCell(item['igst']?.toString() ?? ""),
        tableCell(item['amount']?.toString() ?? ""),
        tableCell(item['remark']?.toString() ?? ""),
      ],
    );
  },
),
                  ],
                ),
              ),

              // ===================================================
              // TOTAL
              // ===================================================

              pw.Row(
                children: [

                  pw.Expanded(
                    child: pw.Container(
                      height: 22,

                      alignment:
                          pw.Alignment.centerRight,

                      padding:
                          const pw.EdgeInsets.only(
                        right: 10,
                      ),

                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          width: 0.5,
                        ),
                      ),

                      child: pw.Text(
                        "TOTAL :",

                        style: pw.TextStyle(
                          fontWeight:
                              pw.FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),

                  pw.Container(
                    width: 90,
                    height: 22,

                    alignment:
                        pw.Alignment.center,

                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(
                        width: 0.5,
                      ),
                    ),

                    child: pw.Text(
                      totalAmount
                          .toStringAsFixed(2),

                      style: pw.TextStyle(
                        fontWeight:
                            pw.FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),

              // ===================================================
              // AMOUNT IN WORDS
              // ===================================================

              pw.Container(
                width: double.infinity,

                padding: const pw.EdgeInsets.all(5),

                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5),
                ),

                child: pw.Text(
                  "Rs : ${amountInWords}",

                  style: const pw.TextStyle(
                    fontSize: 8,
                  ),
                ),
              ),

              // ===================================================
              // TERMS
              // ===================================================

              pw.Container(
                width: double.infinity,

                padding: const pw.EdgeInsets.all(5),

                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5),
                ),

                child: pw.Column(
                  crossAxisAlignment:
                      pw.CrossAxisAlignment.start,

                  children: [

                    pw.Text(
                      "Terms & Condition",

                      style: pw.TextStyle(
                        fontWeight:
                            pw.FontWeight.bold,
                        fontSize: 8,
                      ),
                    ),

                    pw.SizedBox(height: 4),

                    pw.Text(
                      "* PAYMENT : $payment",
                      style: const pw.TextStyle(
                        fontSize: 8,
                      ),
                    ),

                    pw.Text(
                      "* F.O.R : $forValue",
                      style: const pw.TextStyle(
                        fontSize: 8,
                      ),
                    ),

                    pw.Text(
                      "* $terms",
                      style: const pw.TextStyle(
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),

              // ===================================================
              // FOOTER
              // ===================================================

              pw.Container(
                padding: const pw.EdgeInsets.all(8),

                child: pw.Row(
                  mainAxisAlignment:
                      pw.MainAxisAlignment
                          .spaceBetween,

                  children: [

                    pw.Text(
                      "Prepared By",
                      style: const pw.TextStyle(
                        fontSize: 8,
                      ),
                    ),

                    pw.Text(
                      "Checked By",
                      style: const pw.TextStyle(
                        fontSize: 8,
                      ),
                    ),

                    pw.Column(
                      children: [

                        pw.Text(
                          "For: KULVIR TEXTILE PRIVATE LIMITED",

                          style: pw.TextStyle(
                            fontWeight:
                                pw.FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),

                        pw.SizedBox(height: 25),

                        pw.Text(
                          "Authorised Sign",

                          style:
                              const pw.TextStyle(
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );

  Uint8List bytes = await pdf.save();

  await Printing.layoutPdf(
    onLayout: (format) async => bytes,
  );
}

// =======================================================
// HELPERS
// =======================================================

pw.Widget tableHeader(String text) {

  return pw.Container(
    alignment: pw.Alignment.center,
    padding: const pw.EdgeInsets.all(3),

    child: pw.Text(
      text,

      textAlign: pw.TextAlign.center,

      style: pw.TextStyle(
      
        fontSize: 7,
      ),
    ),
  );
}

pw.Widget tableCell(String text) {

  return pw.Container(
    padding: const pw.EdgeInsets.all(3),

    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 7),
    ),
  );
}

pw.Widget infoRow(
  String title,
  String value,
) {

  return pw.Padding(
    padding: const pw.EdgeInsets.only(
      bottom: 5,
    ),

    child: pw.Row(
      children: [

        pw.Text(
          "$title : ",

          style: pw.TextStyle(
          
            fontSize: 8,
          ),
        ),

        pw.Text(
          value,
          style: const pw.TextStyle(
            fontSize: 8,
          ),
        ),
      ],
    ),
  );
}