import 'package:app/store/request/issued_requests.dart';
import 'package:app/store/request/pending_requests.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StoreRequestsPage extends StatelessWidget {
  const StoreRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Store Requests"),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.pending_actions), text: "Pending"),
              Tab(icon: Icon(Icons.check_circle), text: "Issued"),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildStatsSection(),
            const Expanded(
              child: TabBarView(
                children: [
                  PendingRequestsTab(),
                  IssuedRequestsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("requests")
                  .where("status", isEqualTo: "approved")
                  .where("store_status", isEqualTo: "pending").snapshots(),
              builder: (context, snapshot) {
                int count = snapshot.data?.docs.length ?? 0;
                return _statCard(value: "$count", title: "Pending", color: Colors.orange, icon: Icons.pending_actions);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection("requests")
                  .where("store_status", isEqualTo: "issued").snapshots(),
              builder: (context, snapshot) {
                int count = snapshot.data?.docs.length ?? 0;
                return _statCard(value: "$count", title: "Issued", color: Colors.green, icon: Icons.check_circle);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard({required String value, required String title, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(18), border: Border.all(color: color.withOpacity(0.25))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15)),
        ],
      ),
    );
  }
}