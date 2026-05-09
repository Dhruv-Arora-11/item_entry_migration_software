import 'package:app/HR/create_request.dart';
import 'package:app/HR/rejected_requests.dart';
import 'package:app/HR/show_requests.dart';
import 'package:flutter/material.dart';

class HRDashboard extends StatelessWidget {
  const HRDashboard({super.key});

  Widget buildCard(BuildContext context, String title, IconData icon, Color color, Widget page) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16)
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("HR Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildCard(context, "Request Item", Icons.add_box, Colors.blue, const CreateRequestScreen()),
            const SizedBox(height: 16),
            buildCard(context, "My Requests", Icons.list_alt, Colors.green, const HRRequestsScreen()),
            const SizedBox(height: 16),
            buildCard(context, "Rejected Requests", Icons.cancel, Colors.red, const HRRejectedScreen()),
          ],
        ),
      ),
    );
  }
}