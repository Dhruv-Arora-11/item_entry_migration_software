import 'package:app/services/missing_item_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MissingItemsReportDashboard extends StatefulWidget {
  const MissingItemsReportDashboard({super.key});

  @override
  State<MissingItemsReportDashboard> createState() => _MissingItemsReportDashboardState();
}

class _MissingItemsReportDashboardState extends State<MissingItemsReportDashboard> {
  String statusFilter = "Pending";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Light grey background for card contrast
      appBar: AppBar(
        title: const Text("Missing Items Reports", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Toggle Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFilterChip("Pending", "Pending"),
                const SizedBox(width: 12),
                _buildFilterChip("Resolved History", "Resolved"),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("Missing_Items_Reports")
                  .where("status", isEqualTo: statusFilter)
                  .orderBy("created_at", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text("No $statusFilter reports found", style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }

                var docs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return _buildReportCard(data, docs[index].id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Visual helper for Filter Chips
  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: statusFilter == value,
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade900,
      onSelected: (_) => setState(() => statusFilter = value),
    );
  }

  // 🔥 Visual Upgrade: Custom Report Card
  Widget _buildReportCard(Map<String, dynamic> data, String docId) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(data['item_name'] ?? "Unknown", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (statusFilter == "Pending")
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade50, foregroundColor: Colors.green.shade800, elevation: 0),
                    onPressed: () => MissingItemService().resolveMissingItem(docId),
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text("Resolve"),
                  )
                else
                  const Icon(Icons.history, color: Colors.blue),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.receipt_long, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text("Gate Entry: ${data['gate_entry_no'] ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text("Reported: ${data['created_at']?.toDate().toString().substring(0, 16) ?? 'N/A'}", style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
            if (data['reason'] != null) ...[
               const SizedBox(height: 8),
               Text("Note: ${data['reason']}", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade800)),
            ]
          ],
        ),
      ),
    );
  }
}