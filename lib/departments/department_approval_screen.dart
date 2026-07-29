import 'package:app/services/approval_memo_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DepartmentApprovalScreen extends StatefulWidget {
  final String departmentName;

  DepartmentApprovalScreen({super.key, required this.departmentName});

  @override
  State<DepartmentApprovalScreen> createState() =>
      _DepartmentApprovalScreenState();
}

class _DepartmentApprovalScreenState extends State<DepartmentApprovalScreen> {
  final ApprovalMemoService _memoService = ApprovalMemoService();

  // 🔥 Show items for a specific GR Number
  void _showItemDetails(BuildContext context, String grNo) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Items in GR: $grNo"),
        content: SizedBox(
          width: 400,
          height: 300,
          child: StreamBuilder<QuerySnapshot>(
            // 🔥 Debugging: Ensure this path matches exactly what you see in Firestore
            stream: FirebaseFirestore.instance
                .collection("Store_Receipts")
                .doc(grNo)
                .collection("Verified_Items")
                .snapshots(),
            builder: (context, snapshot) {
              // Show loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Show error
              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              // Show empty
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child:
                      Text("No items found in 'Verified_Items' for $grNo.\n\n"
                          "Path: Store_Receipts/$grNo/Verified_Items"),
                );
              }

              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  var d = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(d['item_description'] ?? "No Name"),
                    subtitle: Text(
                        "Bill Qty: ${d['bill_qty']} | Status: ${d['status']}"),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }

  // 🔥 Show rejection dialog
  void _rejectMemo(BuildContext context, String memoId) {
    TextEditingController reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Reason for Rejection"),
        content: TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(hintText: "Enter reason...")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("Approval_Memos")
                  .doc(memoId)
                  .update({
                "status": "Rejected",
                "rejection_reason": reasonCtrl.text
              });
              Navigator.pop(context);
            },
            child: const Text("Reject"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print("Department being queried: '${widget.departmentName}'");
    return Scaffold(
      appBar: AppBar(title: Text("${widget.departmentName} Approvals")),
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 Uses the dynamic departmentName
        stream: _memoService.fetchPendingMemos(widget.departmentName.trim()),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No pending approvals"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(data['memo_no'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          Chip(
                              label: Text("GR: ${data['gr_no']}"),
                              backgroundColor: Colors.yellow.shade100),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Party: ${data['party']}"),
                      Text("Bill: ${data['bill_no']}"),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  _showItemDetails(context, data['gr_no']),
                              child: const Text("View Items"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white),
                              onPressed: () => _rejectMemo(context, doc.id),
                              child: const Text("Reject"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Inside build() -> Elevated Button for Approve
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white),
                              onPressed: () async {
  BuildContext? dialogContext;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      dialogContext = ctx;
      return const Center(
        child: CircularProgressIndicator(),
      );
    },
  );

  try {
    await _memoService.approveMemo(doc.id, data);

    if (dialogContext != null) {
      Navigator.of(dialogContext!).pop();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Approved Successfully"),
        ),
      );
    }
  } catch (e) {
    if (dialogContext != null) {
      Navigator.of(dialogContext!).pop();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
},
                              child: const Text("Approve"),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
