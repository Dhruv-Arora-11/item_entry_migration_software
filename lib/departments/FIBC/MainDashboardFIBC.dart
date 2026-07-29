import 'package:app/departments/FIBC/BOMEntryPage.dart';
import 'package:app/departments/FIBC/BailingDepartmentPage.dart';
import 'package:app/departments/FIBC/CuttingDepartmentPage.dart';
import 'package:app/departments/FIBC/DispatchDepartmentPage.dart';
import 'package:app/departments/FIBC/ReceiptConfirmationPage.dart';
import 'package:app/departments/FIBC/StritchingDepartmentPage.dart';
import 'package:app/departments/FIBC/fibc_po.dart';
import 'package:flutter/material.dart';

class FibcDashboard extends StatelessWidget {
  const FibcDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("FIBC Operations Portal")),
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        children: [
          _buildMenuCard(context, "New Purchase Order", Icons.add_shopping_cart, const FibcPo()),
          // _buildMenuCard(context, "Receipt Confirmation", Icons.check_circle, const FibcReceiptConfirmationPage()),
          _buildMenuCard(context, "Cutting", Icons.content_cut, const CuttingDepartmentPage()),
          _buildMenuCard(context, "Stitching", Icons.layers, const StitchingDepartmentPage()),
          _buildMenuCard(context, "Bailing", Icons.shopping_basket, const BailingDepartmentPage()),
          _buildMenuCard(context, "Dispatch", Icons.local_shipping, const DispatchDepartmentPage()),
          _buildMenuCard(context, "Create BOM", Icons.list_alt, const BomEntryPage()),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Widget page) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, size: 40, color: Colors.blue), Text(title)],
        ),
      ),
    );
  }
}