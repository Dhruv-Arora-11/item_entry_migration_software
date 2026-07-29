import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductionRegisterScreen extends StatefulWidget {
  const ProductionRegisterScreen({super.key});

  @override
  State<ProductionRegisterScreen> createState() => _ProductionRegisterScreenState();
}

class _ProductionRegisterScreenState extends State<ProductionRegisterScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _entries = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _fetchEntries(reset: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _fetchEntries();
      }
    });
  }


  @override
void dispose() {
  _scrollController.dispose();
  _searchController.dispose();
  super.dispose();
}

String getString(Map<String, dynamic> data, String key) {
  final value = data[key];
  return value?.toString() ?? "N/A";
}
Future<void> _fetchEntries({bool reset = false}) async {
  if (reset) {
    setState(() {
      _entries.clear();
      _lastDocument = null;
      _hasMore = true;
      _isLoading = true;
    });
  } else {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
  }

  try {
    final party = _searchController.text.trim();

    Query query =
        FirebaseFirestore.instance.collection("production_entries");

    // ============================
    // CASE 1 : PARTY SEARCH
    // ============================
    if (party.isNotEmpty) {
      query = query
          .where("partyName", isGreaterThanOrEqualTo: party)
          .where("partyName", isLessThanOrEqualTo: "$party\uf8ff")
          .orderBy("partyName")
          .orderBy("entryNo", descending: true);
    }

    // ============================
    // CASE 2 : NORMAL / DATE SEARCH
    // ============================
    else {
      if (_fromDate != null) {
        query = query.where(
          "createdAt",
          isGreaterThanOrEqualTo:
              Timestamp.fromDate(_fromDate!),
        );
      }

      if (_toDate != null) {
        query = query.where(
          "createdAt",
          isLessThan: Timestamp.fromDate(
            _toDate!.add(const Duration(days: 1)),
          ),
        );
      }

      query = query
          .orderBy("createdAt", descending: true)
          .orderBy("entryNo", descending: true);
    }

    // ============================
    // PAGINATION
    // ============================

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.limit(15).get();

    List<DocumentSnapshot> docs = snapshot.docs;

    // ============================
    // Party + Date Filter
    // Filter dates locally
    // ============================

    if (party.isNotEmpty &&
        (_fromDate != null || _toDate != null)) {
      docs = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        if (data["createdAt"] == null) return false;

        final DateTime createdAt =
            (data["createdAt"] as Timestamp).toDate();

        if (_fromDate != null &&
            createdAt.isBefore(_fromDate!)) {
          return false;
        }

        if (_toDate != null &&
            createdAt.isAfter(
              _toDate!.add(const Duration(days: 1)),
            )) {
          return false;
        }

        return true;
      }).toList();
    }

    // ============================
    // REMOVE DUPLICATES
    // ============================

    final existingIds =
        _entries.map((e) => e.id).toSet();

    final newDocs = docs.where((doc) {
      return !existingIds.contains(doc.id);
    }).toList();

    setState(() {
      _entries.addAll(newDocs);

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
      }

      _hasMore = snapshot.docs.length == 15;

      _isLoading = false;
    });
  } catch (e) {
    setState(() => _isLoading = false);

    debugPrint("Firestore Error: $e");
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading && _entries.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty 
                    ? const Center(child: Text("No entries found with this filter."))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _entries.length,
                        itemBuilder: (context, index) => ProductionCard(data: _entries[index].data() as Map<String, dynamic>),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(hintText: "Search Party Name...", prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            onChanged: (val) => _fetchEntries(reset: true),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _datePickerButton("From", _fromDate, (d) => setState(() => _fromDate = d))),
              const SizedBox(width: 12),
              Expanded(child: _datePickerButton("To", _toDate, (d) => setState(() => _toDate = d))),
            ],
          )
        ],
      ),
    );
  }

  Widget _datePickerButton(String label, DateTime? date, Function(DateTime) onPick) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(date == null ? label : DateFormat.yMd().format(date)),
      onPressed: () async {
        final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2025), lastDate: DateTime(2030));
        if (d != null) { onPick(d);

if (_fromDate != null &&
    _toDate != null &&
    _fromDate!.isAfter(_toDate!)) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("From Date cannot be after To Date"),
    ),
  );
  return;
}

_fetchEntries(reset: true); }
      },
    );
  }
}



class ProductionCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const ProductionCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Safe extraction with null-coalescing
    final partyName = (data['partyName'] ?? "Unknown").toString();
    final entryNo = (data['entryNo'] ?? "0").toString();
    final finalMtrs = (data['finalMtrs'] ?? "0.00").toString();
    final netWeight = (data['netWeight'] ?? "0.00").toString();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16,
    vertical: 6,),
      child: ListTile(
        title: Text("Entry #$entryNo", style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Party: $partyName"),
            Text("Final: $finalMtrs Mtr | Net: $netWeight Kg"),
          ],
        ),
        onTap: () => Navigator.push(
          context, 
          MaterialPageRoute(builder: (_) => ProductionDetailsPage(data: data))
        ),
      ),
    );
  }
}

class ProductionDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  const ProductionDetailsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Entry #${data['entryNo']}")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoTile("Party Name", data['partyName']),
          _buildInfoTile("Issue Date", data['issuedDate']),
          _buildInfoTile("Final Meters", "${data['finalMtrs']} m"),
          _buildInfoTile("Net Weight", "${data['netWeight']} kg"),
          _buildInfoTile("Gross Weight", "${data['grossWeight']} kg"),
          _buildInfoTile("Remark", data['remark'] ?? "N/A"),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, dynamic value) {
  return Card(
    child: ListTile(
      title: Text(label),
      trailing: Text(
        value?.toString() ?? "N/A",
      ),
    ),
  );
}
}