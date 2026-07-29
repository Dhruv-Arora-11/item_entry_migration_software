import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// --- Theme Colors Matching Your ERP ---
class AppColors {
  static const Color navy = Color(0xFF0F172A);
  static const Color background = Color(0xFFF1F5F9);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color label = Color(0xFF64748B);
  static const Color infoBlue = Color(0xFF0284C7);
  static const Color green = Color(0xFF10B981);
  static const Color red = Color(0xFFEF4444);
  static const Color orange = Color(0xFFF59E0B);
}

// --- Drop-in Replacement Class ---
class CuttingDepartmentPage extends StatefulWidget {
  const CuttingDepartmentPage({super.key});

  @override
  State<CuttingDepartmentPage> createState() => _CuttingDepartmentPageState();
}

enum RollSortOption { rollNo, entryNo, date, netWeight }

class _CuttingDepartmentPageState extends State<CuttingDepartmentPage> {
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  RollSortOption _sortOption = RollSortOption.rollNo;

  final List<RollIssueCandidate> _allCandidates = [];
  final List<RollIssueCandidate> _visibleCandidates = [];
  final Set<String> _selectedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearchAndSort);
    _loadPendingRolls();
  }

  @override
  void dispose() {
    _searchController.removeListener(_applySearchAndSort);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRolls() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('fibc_roll_receiving')
          .get();

      debugPrint(
        'FIBC_RollIssueToCutting: fetched ${snapshot.docs.length} '
        'document(s) from fibc_roll_receiving',
      );

      final candidates = <RollIssueCandidate>[];
      for (final document in snapshot.docs) {
        final data = document.data();
        final detailsData = data['details'];

        if (detailsData is! List) continue;

        for (var index = 0; index < detailsData.length; index++) {
          final detailData = detailsData[index];
          if (detailData is! Map) continue;

          final detailMap = Map<String, dynamic>.from(detailData);

          final rawFlag = detailMap['issueForCutting'];
          final issueForCutting =
              rawFlag == true ||
              rawFlag?.toString().toLowerCase() == 'true' ||
              rawFlag?.toString() == '1';
          if (issueForCutting) continue;

          final detail = RollReceivingDetail(
            rollNo: (detailMap['rollNo'] ?? '').toString(),
            fabricType: (detailMap['fabricType'] ?? '').toString(),
            sizeCm: _parseDouble(detailMap['sizeCm']),
            gsm: _parseDouble(detailMap['gsm']),
            averageGsm: _parseDouble(detailMap['averageGsm']),
            Average_GPM: _parseDouble(detailMap['Average_GPM']),
            meter: _parseDouble(detailMap['meter']),
            grossWeightKg: _parseDouble(detailMap['grossWeightKg']),
            netWeightKg: _parseDouble(detailMap['netWeightKg']),
            remark: (detailMap['remark'] ?? '').toString(),
            calculatedWeightKg: _parseDouble(detailMap['calculatedWeightKg']),
            differenceKg: _parseDouble(detailMap['differenceKg']),
            issueForCutting: false,
          );

          candidates.add(
            RollIssueCandidate(
              id: '${document.id}-$index',
              entryNo: (data['entryNo'] ?? document.id).toString(),
              date: (data['date'] ?? '').toString(),
              time: (data['time'] ?? '').toString(),
              shift: (data['shift'] ?? '').toString(),
              receivedBy: (data['receivedBy'] ?? '').toString(),
              detailIndex: index,
              detail: detail,
            ),
          );
        }
      }

      if (!mounted) return;

      setState(() {
        _allCandidates
          ..clear()
          ..addAll(candidates);
        _visibleCandidates
          ..clear()
          ..addAll(candidates);
        _applySearchAndSort();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load rolls from Firestore. $error';
      });
      _showSnack('Unable to load rolls from Firestore.', AppColors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applySearchAndSort() {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = _allCandidates.where((candidate) {
      if (query.isEmpty) return true;
      return candidate.detail.rollNo.toLowerCase().contains(query) ||
          candidate.detail.fabricType.toLowerCase().contains(query) ||
          candidate.entryNo.toLowerCase().contains(query) ||
          candidate.date.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      int comparison;
      switch (_sortOption) {
        case RollSortOption.rollNo:
          comparison = a.detail.rollNo.compareTo(b.detail.rollNo);
          break;
        case RollSortOption.entryNo:
          comparison = a.entryNo.compareTo(b.entryNo);
          break;
        case RollSortOption.date:
          comparison = a.date.compareTo(b.date);
          break;
        case RollSortOption.netWeight:
          comparison = a.detail.netWeightKg.compareTo(b.detail.netWeightKg);
          break;
      }
      if (comparison == 0) {
        comparison = a.detail.rollNo.compareTo(b.detail.rollNo);
      }
      return comparison;
    });

    if (mounted) {
      setState(() {
        _visibleCandidates
          ..clear()
          ..addAll(filtered);
      });
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmIssueSelection() async {
    if (_selectedIds.isEmpty) {
      _showSnack('Select at least one roll to issue.', AppColors.orange);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Issue to Cutting Department?'),
        content: Text(
          'You are about to issue ${_selectedIds.length} roll(s) to the Cutting Department. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Issue Now'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _issueSelectedRolls();
    }
  }

  Future<void> _issueSelectedRolls() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final selectedCandidates = _allCandidates
          .where((candidate) => _selectedIds.contains(candidate.id))
          .toList();

      final documentsSnapshot = await FirebaseFirestore.instance
          .collection('fibc_roll_receiving')
          .get();

      final batch = FirebaseFirestore.instance.batch();
      final docsByEntryNo = <String, List<Map<String, dynamic>>>{};

      for (final document in documentsSnapshot.docs) {
        final detailsData = document.data()['details'];
        if (detailsData is! List) continue;

        docsByEntryNo[document.id] = detailsData
            .map((detail) => Map<String, dynamic>.from(detail as Map))
            .toList();
      }

      final groupedByEntryNo = <String, List<RollIssueCandidate>>{};
      for (final candidate in selectedCandidates) {
        groupedByEntryNo
            .putIfAbsent(candidate.entryNo, () => <RollIssueCandidate>[])
            .add(candidate);
      }

      for (final entry in groupedByEntryNo.entries) {
        final entryNo = entry.key;
        final documentId = entryNo;
        final details = docsByEntryNo[documentId];
        if (details == null) continue;

        final detailsToUpdate = List<Map<String, dynamic>>.from(details);
        for (final candidate in entry.value) {
          if (candidate.detailIndex < detailsToUpdate.length) {
            detailsToUpdate[candidate.detailIndex]['issueForCutting'] = true;
          }
        }

        batch.update(
          FirebaseFirestore.instance
              .collection('fibc_roll_receiving')
              .doc(documentId),
          {
            'details': detailsToUpdate,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      if (selectedCandidates.isNotEmpty) {
        await batch.commit();
      }

      if (!mounted) return;

      setState(() {
        _allCandidates.removeWhere((c) => _selectedIds.contains(c.id));
        _visibleCandidates.removeWhere((c) => _selectedIds.contains(c.id));
        _selectedIds.clear();
      });
      _applySearchAndSort();
      _showSnack('Selected rolls were issued successfully.', AppColors.green);
    } catch (error) {
      if (!mounted) return;
      _showSnack('Unable to issue selected rolls. $error', AppColors.red);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedIds.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Cutting Department (Roll Issues)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.navy,
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadPendingRolls,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(selectedCount),
              const SizedBox(height: 16),
              _buildSearchAndSortBar(),
              const SizedBox(height: 16),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                Expanded(
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 40, color: AppColors.red),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _loadPendingRolls,
                              style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else if (_visibleCandidates.isEmpty)
                Expanded(
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2_outlined, size: 40, color: AppColors.label),
                            const SizedBox(height: 12),
                            const Text('No pending rolls available for cutting issue.'),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              onPressed: _loadPendingRolls,
                              style: FilledButton.styleFrom(backgroundColor: AppColors.navy),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(child: _buildRollTable()),
              const SizedBox(height: 12),
              _buildActionBar(selectedCount),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(int selectedCount) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.factory_outlined, color: AppColors.navy),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_allCandidates.length} rolls pending issue',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedCount == 0
                        ? 'Select one or more rolls to issue to cutting.'
                        : '$selectedCount selected for issue.',
                    style: const TextStyle(color: AppColors.label, fontSize: 13),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.infoBlue.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Fetching from fibc_roll_receiving',
                style: TextStyle(color: AppColors.infoBlue, fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndSortBar() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by roll, fabric, entry or date',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.cardBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.infoBlue)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: PopupMenuButton<RollSortOption>(
            tooltip: 'Sort rolls',
            onSelected: (value) {
              setState(() => _sortOption = value);
              _applySearchAndSort();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: RollSortOption.rollNo, child: Text('Sort by roll number')),
              const PopupMenuItem(value: RollSortOption.entryNo, child: Text('Sort by entry number')),
              const PopupMenuItem(value: RollSortOption.date, child: Text('Sort by date')),
              const PopupMenuItem(value: RollSortOption.netWeight, child: Text('Sort by net weight')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.sort, size: 20),
                  const SizedBox(width: 8),
                  Text(_sortOption.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRollTable() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 920),
              child: DataTable(
                headingRowColor: WidgetStateProperty.resolveWith((states) => AppColors.background),
                columnSpacing: 20,
                horizontalMargin: 12,
                onSelectAll: (selected) {
                  setState(() {
                    if (selected == true) {
                      for (final candidate in _visibleCandidates) {
                        _selectedIds.add(candidate.id);
                      }
                    } else {
                      for (final candidate in _visibleCandidates) {
                        _selectedIds.remove(candidate.id);
                      }
                    }
                  });
                },
                columns: const [
                  DataColumn(label: Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Fabric', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Entry', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Net Weight', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Average GPM', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Remark', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _visibleCandidates.map((candidate) {
                  final isSelected = _selectedIds.contains(candidate.id);
                  return DataRow(
                    selected: isSelected,
                    onSelectChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIds.add(candidate.id);
                        } else {
                          _selectedIds.remove(candidate.id);
                        }
                      });
                    },
                    cells: [
                      DataCell(Text(candidate.detail.rollNo, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(candidate.detail.fabricType.isEmpty ? '—' : candidate.detail.fabricType)),
                      DataCell(Text(candidate.entryNo)),
                      DataCell(Text(candidate.date)),
                      DataCell(Text(candidate.detail.netWeightKg.toStringAsFixed(2))),
                      DataCell(Text(candidate.detail.Average_GPM.toStringAsFixed(2))),
                      DataCell(Text(candidate.detail.remark.isEmpty ? '—' : candidate.detail.remark)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(int selectedCount) {
    return Row(
      children: [
        Expanded(
          child: Text(
            selectedCount == 0
                ? 'No rolls selected.'
                : '$selectedCount roll(s) selected for issue.',
            style: const TextStyle(color: AppColors.label, fontWeight: FontWeight.w600),
          ),
        ),
        FilledButton.icon(
          onPressed: _isSubmitting ? null : _confirmIssueSelection,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.navy,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send),
          label: Text(_isSubmitting ? 'Issuing...' : 'Issue Selected'),
        ),
      ],
    );
  }
}

// --- Data Models Required for the Table ---

class RollIssueCandidate {
  const RollIssueCandidate({
    required this.id,
    required this.entryNo,
    required this.date,
    required this.time,
    required this.shift,
    required this.receivedBy,
    required this.detailIndex,
    required this.detail,
  });

  final String id;
  final String entryNo;
  final String date;
  final String time;
  final String shift;
  final String receivedBy;
  final int detailIndex;
  final RollReceivingDetail detail;
}

class RollReceivingDetail {
  final String rollNo;
  final String fabricType;
  final double sizeCm;
  final double gsm;
  final double averageGsm;
  // ignore: non_constant_identifier_names
  final double Average_GPM;
  final double meter;
  final double grossWeightKg;
  final double netWeightKg;
  final String remark;
  final double calculatedWeightKg;
  final double differenceKg;
  final bool issueForCutting;

  RollReceivingDetail({
    required this.rollNo,
    required this.fabricType,
    required this.sizeCm,
    required this.gsm,
    required this.averageGsm,
    // ignore: non_constant_identifier_names
    required this.Average_GPM,
    required this.meter,
    required this.grossWeightKg,
    required this.netWeightKg,
    required this.remark,
    required this.calculatedWeightKg,
    required this.differenceKg,
    required this.issueForCutting,
  });
}