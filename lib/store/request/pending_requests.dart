import 'package:app/store/request/components/request_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PendingRequestsTab extends StatelessWidget {
  const PendingRequestsTab({super.key});

  String getHeader(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) return "TODAY";
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) return "YESTERDAY";
    return DateFormat("dd MMM yyyy").format(date);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("requests")
          .where("status", isEqualTo: "approved")
          .where("store_status", isEqualTo: "pending")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        var docs = snapshot.data!.docs;
        docs.sort((a, b) => (b['created_at'] as Timestamp).compareTo(a['created_at'] as Timestamp));

        String currentHeader = "";

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            var doc = docs[i];
            var d = doc.data() as Map<String, dynamic>;
            DateTime created = (d['created_at'] as Timestamp).toDate();
            String header = getHeader(created);
            bool showHeader = header != currentHeader;
            if (showHeader) currentHeader = header;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showHeader)
                  Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Text(header, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                // RequestCard now handles the 'items' array inside doc
                RequestCard(doc: doc, pending: true),
              ],
            );
          },
        );
      },
    );
  }
}