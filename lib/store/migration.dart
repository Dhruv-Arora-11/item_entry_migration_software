import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> migrateAmountToDouble() async {
  final firestore = FirebaseFirestore.instance;
  final itemsRef = firestore.collection('Items');

  try {
    debugPrint("Starting Bulletproof Amount migration...");
    
    // Fetch all items
    final snapshot = await itemsRef.get();
    
    var batch = firestore.batch();
    int batchCount = 0;
    int totalUpdated = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final amount = data['Amount'];

      if (amount == null) continue;

      double? newAmount;

      // 1. If it's any type of number (int or double), force it to a double
      if (amount is num) {
        newAmount = amount.toDouble();
      } 
      // 2. If it was accidentally saved as a String in the past, parse it
      else if (amount is String) {
        newAmount = double.tryParse(amount);
      }

      // If we successfully converted it, add it to the batch
      if (newAmount != null) {
        batch.update(doc.reference, {'Amount': newAmount});
        
        batchCount++;
        totalUpdated++;

        // Commit every 500 items (Firestore limit)
        if (batchCount == 500) {
          await batch.commit();
          debugPrint("Committed a batch of 500...");
          batch = firestore.batch(); 
          batchCount = 0;
        }
      }
    }

    // Commit any leftovers
    if (batchCount > 0) {
      await batch.commit();
    }

    debugPrint('Migration complete! Forced $totalUpdated items to double.');
    
  } catch (e) {
    debugPrint('Error during migration: $e');
  }
}