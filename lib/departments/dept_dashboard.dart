import 'package:app/departments/create_request.dart';
import 'package:app/departments/department_approval_screen.dart';
import 'package:app/departments/rejected_requests.dart';
import 'package:app/departments/show_requests.dart';
import 'package:app/auth/login_func.dart';
// 🔥 ADD THIS IMPORT
import 'package:flutter/material.dart';

class DepartmentDashboard extends StatelessWidget {
  final String departmentName;

  const DepartmentDashboard({
    super.key,
    required this.departmentName,
  });

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
      appBar: AppBar(
        title: Text("$departmentName Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              bool? logout = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                      ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Logout")),
                    ],
                  );
                },
              );
              if (logout == true) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      // 🔥 Wrapped in SingleChildScrollView so cards don't overflow
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildCard(context, "Indent Item", Icons.add_box, Colors.blue, 
                CreateRequestScreen(departmentName: departmentName)),
            
            const SizedBox(height: 16),
            
            // 🔥 NEW: Incoming Material Approvals
            buildCard(context, "Incoming Material Approvals", Icons.inventory_outlined, Colors.orange, 
                DepartmentApprovalScreen(departmentName: departmentName)),
            
            const SizedBox(height: 16),
            
            buildCard(context, "My Requests", Icons.list_alt, Colors.green, 
                HRRequestsScreen(departmentName: departmentName)),
            
            const SizedBox(height: 16),
            
            buildCard(context, "Rejected Requests", Icons.cancel, Colors.red, 
                HRRejectedScreen(departmentName: departmentName)),
          ],
        ),
      ),
    );
  }
}