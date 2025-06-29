import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  String _currentTypeFilter = 'All';
  String? _filterTypeValue;
  double? _filterRatingValue;
  String _currentSort = 'newest';

  void _showTypeFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(leading: const Icon(Icons.select_all), title: const Text('All'), onTap: () => _applyTypeFilter('All', null)),
              ListTile(leading: const Icon(Icons.psychology_outlined), title: const Text('Career - Personality'), onTap: () => _applyTypeFilter('Personality', 'Personality-Based')),
              ListTile(leading: const Icon(Icons.track_changes_outlined), title: const Text('Career - Skills'), onTap: () => _applyTypeFilter('Skills', 'Skills-Based')),
              ListTile(leading: const Icon(Icons.school_outlined), title: const Text('College'), onTap: () => _applyTypeFilter('College', 'College-Based')),
            ],
          ),
        );
      },
    );
  }

  void _applyTypeFilter(String filterName, String? queryValue) {
    setState(() {
      _currentTypeFilter = filterName;
      _filterTypeValue = queryValue;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('feedback');

    if (_filterTypeValue != null) {
      query = query.where('feedbackType', isEqualTo: _filterTypeValue);
    }
    if (_filterRatingValue != null) {
      query = query.where('rating', isEqualTo: _filterRatingValue);
    }
    
    query = query.orderBy('timestamp', descending: _currentSort == 'newest');

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('User Feedback Panel', style: TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor: Colors.green.shade700,
            floating: true,
            snap: true,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          SliverPersistentHeader(
            delegate: _SliverFilterHeaderDelegate(
              currentSort: _currentSort,
              onSortPressed: () {
                setState(() {
                  _currentSort = _currentSort == 'newest' ? 'oldest' : 'newest';
                });
              },
              onTypeFilterPressed: _showTypeFilterOptions,
              currentTypeFilter: _currentTypeFilter,
              currentRatingFilter: _filterRatingValue,
              onRatingFilterChanged: (newRating) {
                setState(() {
                  if (_filterRatingValue == newRating) {
                    _filterRatingValue = null;
                  } else {
                    _filterRatingValue = newRating;
                  }
                });
              }, 
            ),
            pinned: true,
          ),
          StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              if (snapshot.hasError) return SliverFillRemaining(child: Center(child: Text('Error: ${snapshot.error}')));
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SliverFillRemaining(child: Center(child: Text('No feedback found for this filter.')));

              final feedbackDocs = snapshot.data!.docs;

              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = feedbackDocs[index];
                      final feedback = doc.data() as Map<String, dynamic>;
                      return _buildFeedbackCard(feedback, doc.id);
                    },
                    childCount: feedbackDocs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback, String docId) {
    final timestamp = feedback['timestamp'] as Timestamp?;
    final date = timestamp != null ? DateFormat.yMMMd().add_jm().format(timestamp.toDate()) : 'N/A';
    final double rating = (feedback['rating'] as num?)?.toDouble() ?? 0.0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.green.shade200, width: 1.5),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        title: Text(feedback['feedbackText'] ?? 'No text provided.', maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            RatingBarIndicator(
              rating: rating,
              itemBuilder: (context, index) => const Icon(Icons.star, color: Colors.amber),
              itemCount: 5,
              itemSize: 20.0,
            ),
            const SizedBox(height: 8),
            Text('From: ${feedback['userEmail'] ?? 'Unknown'}\nDate: $date'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push('/admin/feedback-detail/$docId');
        },
      ),
    );
  }
}

class _SliverFilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final VoidCallback onSortPressed;
  final VoidCallback onTypeFilterPressed;
  final ValueChanged<double?> onRatingFilterChanged;
  final String currentSort;
  final String currentTypeFilter;
  final double? currentRatingFilter;

  _SliverFilterHeaderDelegate({
    required this.onSortPressed,
    required this.onTypeFilterPressed,
    required this.onRatingFilterChanged,
    required this.currentSort,
    required this.currentTypeFilter,
    required this.currentRatingFilter,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white.withOpacity(0.95),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Row(
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
                  onPressed: onTypeFilterPressed,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12.0), side: BorderSide(color: Colors.grey.shade400), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
                  icon: const Icon(Icons.filter_list, color: Colors.grey),
                  label: Text(currentTypeFilter, style: const TextStyle(color: Colors.grey, overflow: TextOverflow.ellipsis)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildRatingChip(context, null, 'All'),
                ...[5.0, 4.5, 4.0, 3.5, 3.0, 2.5, 2.0, 1.5, 1.0].map((rating) => _buildRatingChip(context, rating, '$rating ★')),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRatingChip(BuildContext context, double? rating, String label) {
    final bool isSelected = currentRatingFilter == rating;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onRatingFilterChanged(rating),
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.green.shade200,
        labelStyle: TextStyle(
          color: isSelected ? Colors.green.shade900 : Colors.black54,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
        ),
        shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.green : Colors.grey.shade300)),
      ),
    );
  }

  @override
  double get maxExtent => 120.0;
  @override
  double get minExtent => 120.0;
  @override
  bool shouldRebuild(covariant _SliverFilterHeaderDelegate oldDelegate) {
    return oldDelegate.currentSort != currentSort || 
           oldDelegate.currentTypeFilter != currentTypeFilter ||
           oldDelegate.currentRatingFilter != currentRatingFilter;
  }
}
