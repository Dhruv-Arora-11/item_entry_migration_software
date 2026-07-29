import 'package:app/global_components/snackbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> issueItem(
  QueryDocumentSnapshot doc,
  BuildContext context,
) async {

  try {

    var requestData =
        doc.data() as Map<String, dynamic>;

    String itemCode =
        requestData['item_code'];

    int requestedQty =
        requestData['requested_qty'];

    // FIND ITEM
    var itemQuery =
        await FirebaseFirestore.instance
            .collection("Items")
            .where(
              "Item_Code",
              isEqualTo: itemCode,
            )
            .get();

    // ITEM NOT FOUND
    if (itemQuery.docs.isEmpty) {

      showSnack(
  context,
  "Item does not exist in inventory",
  Colors.red,
);

      return;
    }

    var itemDoc =
        itemQuery.docs.first;

    var itemData =
        itemDoc.data();

    int currentStock =
        itemData['Opening_Stock'] ?? 0;

    // INSUFFICIENT STOCK
    if (currentStock <
        requestedQty) {

      showSnack(
  context,
  "Stock available: $currentStock | Requested: $requestedQty",
  Colors.orange,
);

      return;
    }

    // UPDATE STOCK
    await itemDoc.reference.update({
      "Opening_Stock":
          currentStock - requestedQty,
    });

    // UPDATE REQUEST
    await doc.reference.update({

      "store_status": "issued",

      "issued_at":
          FieldValue.serverTimestamp(),

      "issued_by":
          "store_manager",
    });

    showSnack(
  context,
  "Item Issued Successfully",
  Colors.green,
);

  } catch (e) {

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          e.toString(),
        ),
      ),
    );
  }
}