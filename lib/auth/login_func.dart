import 'package:app/departments/FIBC/MainDashboardFIBC.dart';
import 'package:app/departments/Production/Dashboard.dart';
import 'package:app/departments/dept_dashboard.dart';
import 'package:app/departments/gate/gate_entry_homeScreen.dart';
import 'package:app/store/FIBC_Part/production_log_page.dart';
import 'package:app/store/Dashboard.dart';
import 'package:app/super_admin/super_admin.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/core/global_user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false;

  Future<void> login() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter username & password")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if(username == "gate1" && password == "pass1"){
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const GateEntryScreen(),
            ),
          );
      }else if (username == 'fibc' && password == "fibc") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const FibcDashboard(),
            ),
          );
      }
      var query = await FirebaseFirestore.instance
          .collection("users")
          .where("username", isEqualTo: username)
          .where("password", isEqualTo: password)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid credentials")),
        );
        setState(() => isLoading = false);
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Success")),
        );
        currentUser = query.docs.first.data();

        String role = currentUser?['role'] ?? "user";

        String department = currentUser?['department_name'] ?? "";

        if(department == "production"){
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProdDashboard(),
            ),
          );
        }

        else if (role == "super_admin") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const SuperAdminScreen(),
            ),
          );
        }else {
          if (department == "") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => StoreDashboard(
                  current_user: currentUser,
                ),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => DepartmentDashboard(
                  departmentName: department,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF2FB), Color(0xFFF7F9FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline,
                        size: 50, color: Color(0xFF1D4E89)),
                    const SizedBox(height: 10),
                    const Text(
                      "Login",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: "Username",
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text("Login"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
