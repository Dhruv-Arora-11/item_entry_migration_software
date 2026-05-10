import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> exportGroupsToExcelWeb() async {
  try {
    var snapshot =
        await FirebaseFirestore.instance.collection("groups").get();

    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    // 🔹 HEADER
    sheet.appendRow([
      TextCellValue("Group Name"),
      TextCellValue("Subgroup Name"),
    ]);

    // 🔹 DATA
    for (var doc in snapshot.docs) {
      var data = doc.data();

      String groupName = data['name'] ?? "";
      List subgroups = data['subgroups'] ?? [];

      if (subgroups.isEmpty) {
        sheet.appendRow([
          TextCellValue(groupName),
          TextCellValue(""),
        ]);
      } else {
        for (var sub in subgroups) {
          String subName = sub is Map
              ? sub['name'] ?? ""
              : sub.toString();

          sheet.appendRow([
            TextCellValue(groupName),
            TextCellValue(subName),
          ]);
        }
      }
    }

    // 🔥 CONVERT TO BYTES
    final bytes = excel.encode();

    if (bytes == null) return;

    // 🔥 DOWNLOAD FILE
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);


    html.Url.revokeObjectUrl(url);

    print("Download triggered");
  } catch (e) {
    print("Export Error: $e");
  }
}