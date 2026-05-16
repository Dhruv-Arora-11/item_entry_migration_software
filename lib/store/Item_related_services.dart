import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;

class ItemService {
  final _db = FirebaseFirestore.instance;

  bool canEdit(Map item, bool isAdmin) {
    if (isAdmin) return true;

    DateTime? createdAt = item['Create_at']?.toDate();
    bool unlocked = item['edit_unlocked'] == true;

    if (createdAt == null) return false;

    if (DateTime.now().difference(createdAt).inDays < 15) {
      return true;
    }

    return unlocked;
  }

  Future<String> getSystemIP() async {
    try {
      final response = await http.get(Uri.parse('https://api.ipify.org'));
      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      debugPrint("IP Error: $e");
    }
    return 'Unknown IP';
  }

  Future<void> updateItem({
    required String docId,
    required Map<String, dynamic> oldData,
    required Map<String, dynamic> newData,
    required String userName,
  }) async {
    Map<String, dynamic> changes = {};

    newData.forEach((key, value) {
      if (oldData[key] != value) {
        changes[key] = {
          "old": oldData[key],
          "new": value,
        };
      }
    });

    //UPDATE ITEM
    await _db.collection("Items").doc(docId).update(newData);

    //SAVE LOG
    await _db.collection("item_logs").add({
      "item_id": docId,
      "item_code": oldData['Item_Code'],
      "edited_by": userName,
      "edited_at": FieldValue.serverTimestamp(),
      "changes": changes,
    });
  }

  //STREAM LOGS
  Stream<QuerySnapshot> getLogs(String itemId) {
    return _db
        .collection("item_logs")
        .where("item_id", isEqualTo: itemId)
        .orderBy("edited_at", descending: true)
        .snapshots();
  }

  //DELETE LOGS (LAST N DAYS)
  Future<void> deleteLogsLastNDays(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));

    final snapshot = await _db
        .collection("item_logs")
        .where("edited_at", isLessThan: cutoff)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  //UNLOCK ITEM (ADMIN)
  Future<void> unlockItem(String docId) async {
    await _db.collection("Items").doc(docId).update({"edit_locked": false});
  }

  // for printing the selected item in view item screen. the selected items will be printed and saved in form of pdf
  Future<void> exportSelectedItemsPdf({
  required dynamic selectedDocs,
  required String groupName,
  required String subgroupName,
}) async {
    if (selectedDocs.isEmpty) return;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return [
            pw.Text(
              "Stock Report",
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
  mainAxisAlignment:
      pw.MainAxisAlignment.spaceBetween,

  children: [

    pw.Text(
      "Date : ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
    ),

    pw.Text(
      "Group : $groupName",
    ),

    pw.Text(
      "Subgroup : $subgroupName",
    ),
  ],
),

pw.SizedBox(height: 15),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(),
              headers: [
                "Item Code",
                "Item Name",
                "Design No",
                "Size",
                "Stock",
                "Min Stock",
                "Unit",
                "Amount",
              ],
              data: List<List<String>>.from(
                selectedDocs.map((doc) {
                  var d = doc.data() as Map<String, dynamic>;

                  return [
                    d['Item_Code']?.toString() ?? "",
                    d['Item_Name']?.toString() ?? "",
                    d['Design_No']?.toString() ?? "",
                    d['Size']?.toString() ?? "",
                    d['Opening_Stock']?.toString() ?? "0",
                    d['Min_Stock']?.toString() ?? "0",
                    d['Unit']?.toString() ?? "",
                    d['Amount']?.toString() ?? "0",
                  ];
                }),
              ),
            ),
          ];
        },
      ),
    );

    Uint8List bytes = await pdf.save();

    final blob = html.Blob([bytes]);

    final url = html.Url.createObjectUrlFromBlob(blob);

    html.AnchorElement(href: url)
      ..setAttribute(
        "download",
        "selected_items.pdf",
      )
      ..click();

    html.Url.revokeObjectUrl(url);
  }
}
