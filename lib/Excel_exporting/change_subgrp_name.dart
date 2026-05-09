import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> fixSubgroupName() async {
  var snapshot = await FirebaseFirestore.instance
      .collection("Items")
      .where("SubGroup_Name", isEqualTo: "STITCHING M/C - BMC-802")
      .get();

  for (var doc in snapshot.docs) {
    await doc.reference.update({
      "SubGroup_Name": "STITCHING M/C – BMC-802",
      "SubGroup_ID" : "STITCHING M/C – BMC-802"
    });
  }

  print("✅ Updated ${snapshot.docs.length} items");
}

Future<void> fixSubgroupNameElectrical() async {
  var snapshot = await FirebaseFirestore.instance
      .collection("Items")
      .where("SubGroup_Name", isEqualTo: "ELECTRICAL")
      .get();

  for (var doc in snapshot.docs) {
    await doc.reference.update({
      "SubGroup_Name": "ELECTRICAL/ENGINEERING",
      "SubGroup_ID" : "ELECTRICAL/ENGINEERING"

    });
  }

  print("✅ Updated ${snapshot.docs.length} items");
}


Future<void> findDocID() async {
  var snapshot = await FirebaseFirestore.instance
      .collection("Items")
      .where("SubGroup_Name", isEqualTo: "STITCHING M/C - BMC-802")
      .get();


  print("✅ ${snapshot.docs.length} items");
  print(snapshot.docs.first.id);
}


// STITCHING M/C – BMC-802
// STITCHING M/C - BMC-802
// STITCHING M/C – BMC-802
// STITCHING M/C - BMC-802
// STITCHING M/C – BMC-802