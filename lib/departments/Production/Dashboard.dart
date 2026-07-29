import 'package:app/departments/Production/ListProductionEntries.dart';
import 'package:app/departments/Production/LoomEfficiencyEntrySystem.dart';
import 'package:app/departments/Production/ProductionEntrySystem.dart';
import 'package:flutter/material.dart';

class ProdDashboard extends StatelessWidget {

  ProdDashboard({
    super.key,
  });


  Widget buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: const Color(0xFF1D4E89)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16)
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Production Manager"),
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F7FB), Color(0xFFEAF2FB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage Production Unit",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102A43),
              ),
            ),

            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  // 🔹 CREATE
                  
                  buildCard(
                    context: context,
                    title: "Loom Efficiency Entry System",
                    subtitle: "Create and Print New Loom Entries",
                    icon: Icons.receipt_long_outlined,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const Loomefficiencyentrysystem(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  buildCard(
  context: context,
  title: "Production Entry System",
  subtitle: "Create and Manage Production Entries",
  icon: Icons.factory_outlined,
  onTap: () {
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductionEntrySystem(),
      ),
    );
  },
),

buildCard(
  context: context,
  title: "Production Entry System",
  subtitle: "Create and Manage Production Entries",
  icon: Icons.factory_outlined,
  onTap: () {
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProductionRegisterScreen(),
      ),
    );
  },
),
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}
