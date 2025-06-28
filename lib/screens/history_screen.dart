import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:async'; 
import 'package:flutter/rendering.dart'; 

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _currentFilter = 'All'; 
  String? _filterQueryValue; 
  String _currentSort = 'newest';

  Future<void> _showDeleteConfirmationDialog(String reportId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Confirm Deletion'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to delete this report?'),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                _deleteReport(reportId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteReport(String reportId) async {
    final User? currentUser = _auth.currentUser;
    if (currentUser == null) return;
    try {
      await _firestore.collection('users').doc(currentUser.uid).collection('reports').doc(reportId).delete();
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report deleted successfully.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
       if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete report: $e'), backgroundColor: Colors.red),
        );
       }
    }
  }
  
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(leading: const Icon(Icons.select_all), title: const Text('All'), onTap: () => _applyFilter('All', null)),
              ListTile(leading: const Icon(Icons.psychology_outlined), title: const Text('Career - Personality'), onTap: () => _applyFilter('Personality', 'Personality-Based')),
              ListTile(leading: const Icon(Icons.track_changes_outlined), title: const Text('Career - Skills'), onTap: () => _applyFilter('Skills', 'Skills-Based')),
              ListTile(leading: const Icon(Icons.school_outlined), title: const Text('College'), onTap: () => _applyFilter('College', 'College-Based')),
            ],
          ),
        );
      },
    );
  }

  void _applyFilter(String filterName, String? queryValue) {
    setState(() {
      _currentFilter = filterName;
      _filterQueryValue = queryValue;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _auth.currentUser;
    Query query = _firestore.collection('users').doc(currentUser?.uid ?? 'null_user').collection('reports');

    if (_filterQueryValue != null) {
      query = query.where('predictionType', isEqualTo: _filterQueryValue);
    }
    query = query.orderBy('timestamp', descending: _currentSort == 'newest');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text('Prediction History', style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
                    const SizedBox(height: 8.0),
                    const Text('View your past predictions and reports', style: TextStyle(fontSize: 16.0, color: Colors.grey), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverFilterHeaderDelegate(
                onSortPressed: () => setState(() => _currentSort = _currentSort == 'newest' ? 'oldest' : 'newest'),
                onFilterPressed: _showFilterOptions,
                currentSort: _currentSort,
                currentFilter: _currentFilter,
              ),
              pinned: true,
              floating: true, 
            ),
            StreamBuilder<QuerySnapshot>(
              stream: currentUser != null ? query.snapshots() : null,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.green)));
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(child: Center(child: Text("Error: ${snapshot.error}")));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        _filterQueryValue != null
                            ? 'No reports match your filter.\nTry selecting a different option!'
                            : 'Your prediction history is empty.\nComplete an assessment to get started!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16.0, color: Colors.grey),
                      ),
                    ),
                  );
                }
                
                final reports = snapshot.data!.docs;
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final report = reports[index].data() as Map<String, dynamic>;
                        report['id'] = reports[index].id; 
                        return _buildReportCard(report);
                      },
                      childCount: reports.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final String reportId = report['id'];
    final String predictedRole = report['predictedRole'] ?? 'Unknown Role';
    final String predictionType = report['predictionType'] ?? 'N/A';
    final Timestamp? timestamp = report['timestamp'] as Timestamp?;
    // --- UPDATED DATE FORMAT ---
    final String formattedDate = timestamp != null 
        ? DateFormat('MMM dd, yyyy  h:mm a').format(timestamp.toDate()) 
        : 'N/A';
    final bool hasFeedback = report['feedbackGiven'] ?? false;
    
    final bool isCollegePrediction = predictionType == 'College-Based';
    final IconData titleIcon = isCollegePrediction ? Icons.school_outlined : Icons.work_outline;
    final String titleText = isCollegePrediction ? 'College Prediction' : 'Career Prediction';

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.green.shade200, width: 1.5),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: () {
          if (isCollegePrediction) {
            context.push('/college-faculty-report/$reportId/${Uri.encodeComponent(predictedRole)}');
          } else {
            context.push('/career-report/$reportId/${Uri.encodeComponent(predictedRole)}');
          }
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(titleIcon, color: Colors.green.shade700),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(titleText, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.black87)),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _showDeleteConfirmationDialog(reportId),
                    tooltip: 'Delete Report',
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              
              // --- UPDATED LAYOUT FOR DETAILS ---
              // Changed from a Row to a Column
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 8.0),
                      Text(formattedDate, style: const TextStyle(fontSize: 14.0, color: Colors.grey)),
                    ],
                  ),
                  if (!isCollegePrediction) ...[
                    const SizedBox(height: 8.0), // Add spacing between the stacked items
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                        const SizedBox(width: 8.0),
                        Text(predictionType, style: const TextStyle(fontSize: 14.0, color: Colors.grey)),
                      ],
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 12.0),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text('Result: $predictedRole', style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (hasFeedback)
                        const Row(children: [Icon(Icons.check_circle, size: 18, color: Colors.green), SizedBox(width: 4), Text('Feedback', style: TextStyle(fontSize: 12, color: Colors.green))])
                      else
                        const Row(children: [Icon(Icons.cancel_outlined, size: 18, color: Colors.grey), SizedBox(width: 4), Text('No Feedback', style: TextStyle(fontSize: 12, color: Colors.grey))]),
                      const SizedBox(height: 4.0),
                      const Text('Tap to view', style: TextStyle(fontSize: 12.0, color: Colors.green, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onSortPressed;
  final VoidCallback onFilterPressed;
  final String currentSort;
  final String currentFilter;

  _SliverFilterHeaderDelegate({
    required this.onSortPressed,
    required this.onFilterPressed,
    required this.currentSort,
    required this.currentFilter,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onSortPressed,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12.0), side: BorderSide(color: Colors.grey.shade400), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
              icon: Icon(currentSort == 'newest' ? Icons.arrow_downward : Icons.arrow_upward, color: Colors.grey),
              label: Text('Sort: ${currentSort == 'newest' ? 'Newest' : 'Oldest'}', style: const TextStyle(color: Colors.grey)),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onFilterPressed,
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12.0), side: BorderSide(color: Colors.grey.shade400), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
              icon: const Icon(Icons.filter_list, color: Colors.grey),
              label: Text('Filter: $currentFilter', style: const TextStyle(color: Colors.grey, overflow: TextOverflow.ellipsis)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 60.0;

  @override
  double get minExtent => 60.0;

  @override
  bool shouldRebuild(covariant _SliverFilterHeaderDelegate oldDelegate) {
    return oldDelegate.currentSort != currentSort || oldDelegate.currentFilter != currentFilter;
  }
}
