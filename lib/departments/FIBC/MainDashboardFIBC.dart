import 'package:flutter/material.dart';

// Import your existing pages here (Make sure the paths match your project)
import 'package:app/departments/FIBC/BOMEntryPage.dart';
import 'package:app/departments/FIBC/BailingDepartmentPage.dart';
import 'package:app/departments/FIBC/CuttingDepartmentPage.dart';
import 'package:app/departments/FIBC/DispatchDepartmentPage.dart';
import 'package:app/departments/FIBC/ReceiptConfirmationPage.dart';
import 'package:app/departments/FIBC/StritchingDepartmentPage.dart';
import 'package:app/departments/FIBC/fibc_po.dart';

/// Shared Design tokens matching the FIBC ERP Interface
class ERPTheme {
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color headerNavy = Color(0xFF1E293B);
  static const Color accentBlue = Color(0xFF0284C7);
  static const Color backgroundBg = Color(0xFFF1F5F9);
  static const Color cardBg = Colors.white;
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
}

class FibcDashboard extends StatelessWidget {
  const FibcDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ERPTheme.backgroundBg,
      body: Column(
        children: [
          // Consistent ERP Top Header
          _buildTopHeader(),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dashboard Welcome Area
                  const Text(
                    "FIBC Operations Portal",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ERPTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select a module to manage your workflow.",
                    style: TextStyle(
                      fontSize: 14,
                      color: ERPTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Responsive Grid of Modules
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Dynamically adjust columns based on screen width (Responsive for Web/Desktop/Mobile)
                        int crossAxisCount = 2;
                        if (constraints.maxWidth > 1200) {
                          crossAxisCount = 5;
                        } else if (constraints.maxWidth > 900) {
                          crossAxisCount = 4;
                        } else if (constraints.maxWidth > 600) {
                          crossAxisCount = 3;
                        }

                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.1, // Adjusts height vs width of cards
                          children: [
                            _buildMenuCard(
                              context, 
                              title: "New Purchase Order", 
                              icon: Icons.add_shopping_cart, 
                              page: const FibcPo(), 
                              color: const Color(0xFF2563EB), // Blue
                            ),
                            // _buildMenuCard(context, title: "Receipt Confirmation", icon: Icons.check_circle, page: const FibcReceiptConfirmationPage(), color: const Color(0xFF10B981)), // Teal
                            _buildMenuCard(
                              context, 
                              title: "Cutting", 
                              icon: Icons.content_cut, 
                              page: const CuttingDepartmentPage(), 
                              color: const Color(0xFFF59E0B), // Orange
                            ),
                            _buildMenuCard(
                              context, 
                              title: "Stitching", 
                              icon: Icons.layers_outlined, 
                              page: const StitchingReceiveScreen(), // Pointing to your new UI
                              color: const Color(0xFF8B5CF6), // Purple
                            ),
                            _buildMenuCard(
                              context, 
                              title: "Bailing", 
                              icon: Icons.shopping_basket_outlined, 
                              page: const BailingDepartmentPage(), 
                              color: const Color(0xFFEC4899), // Pink
                            ),
                            _buildMenuCard(
                              context, 
                              title: "Dispatch", 
                              icon: Icons.local_shipping_outlined, 
                              page: const DispatchDepartmentPage(), 
                              color: const Color(0xFF14B8A6), // Teal
                            ),
                            _buildMenuCard(
                              context, 
                              title: "Create BOM", 
                              icon: Icons.list_alt, 
                              page: const BomEntryPage(), 
                              color: const Color(0xFFEF4444), // Red
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildTopHeader() {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: ERPTheme.headerNavy,
      child: Row(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.dashboard, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'KULVIR GROUP | FIBC ERP',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 12),
          Container(
            height: 32,
            width: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ERPTheme.accentBlue,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, {required String title, required IconData icon, required Widget page, required Color color}) {
    return Container(
      decoration: BoxDecoration(
        color: ERPTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ERPTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: color.withOpacity(0.04), // Subtle hover effect matching the icon color
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Container
                Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 30, color: color),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ERPTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}