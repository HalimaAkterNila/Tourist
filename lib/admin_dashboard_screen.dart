import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isAdmin = false;
  bool _loading = true;
  int _bookings = 0;
  int _users = 0;
  int _places = 0;
  List<Map<String, dynamic>> _pendingSuggestions = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final profile = await supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', user.id)
          .single();

      if (profile['is_admin'] == true) {
        final bookings = await supabase.from('bookings').select('id');
        final users = await supabase.from('profiles').select('id');
        final places = await supabase.from('places').select('id');
        final suggestions = await supabase
            .from('place_suggestions')
            .select('*, profiles(full_name)')
            .eq('status', 'pending')
            .order('created_at', ascending: false);
        setState(() {
          _isAdmin = true;
          _bookings = (bookings as List).length;
          _users = (users as List).length;
          _places = (places as List).length;
          _pendingSuggestions = List<Map<String, dynamic>>.from(suggestions);
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _approveSuggestion(Map<String, dynamic> suggestion) async {
    try {
      // Insert into places table
      await supabase.from('places').insert({
        'division': suggestion['division'],
        'name': suggestion['name'],
        'description': suggestion['description'],
        'category': suggestion['category'],
        'latitude': suggestion['latitude'],
        'longitude': suggestion['longitude'],
        'image_url': suggestion['image_url'],
      });
      // Update suggestion status to approved
      await supabase
          .from('place_suggestions')
          .update({'status': 'approved'})
          .eq('id', suggestion['id']);
      // Refresh
      _refreshSuggestions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Place approved and added to list.')),
        );
      }
    } catch (e) {
      _showError('Approve failed: $e');
    }
  }

  Future<void> _rejectSuggestion(Map<String, dynamic> suggestion) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Suggestion'),
        content: const Text('Are you sure you want to reject this place suggestion?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reject', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await supabase
          .from('place_suggestions')
          .update({'status': 'rejected'})
          .eq('id', suggestion['id']);
      _refreshSuggestions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Suggestion rejected.')),
        );
      }
    } catch (e) {
      _showError('Reject failed: $e');
    }
  }

  Future<void> _refreshSuggestions() async {
    final suggestions = await supabase
        .from('place_suggestions')
        .select('*, profiles(full_name)')
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    setState(() {
      _pendingSuggestions = List<Map<String, dynamic>>.from(suggestions);
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 60, color: Colors.grey),
              SizedBox(height: 16),
              Text('Admin access required.', style: TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _statCard('Total Bookings', _bookings, Icons.book, Colors.blue),
                const SizedBox(width: 12),
                _statCard('Total Users', _users, Icons.people, MyApp.secondaryColor),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard('Total Places', _places, Icons.place, MyApp.primaryColor),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Pending Place Suggestions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_pendingSuggestions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No pending suggestions.'),
              )
            else
              Expanded(
                flex: 1,
                child: ListView.builder(
                  itemCount: _pendingSuggestions.length,
                  itemBuilder: (context, i) {
                    final s = _pendingSuggestions[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.add_location, color: Colors.orange),
                        title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Division: ${s['division']}'),
                            if (s['category'] != null) Text('Category: ${s['category']}'),
                            if (s['description'] != null) Text('${s['description']}', maxLines: 2, overflow: TextOverflow.ellipsis),
                            Text('Suggested by: ${s['profiles']?['full_name'] ?? 'Unknown'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => _approveSuggestion(s),
                              tooltip: 'Approve',
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _rejectSuggestion(s),
                              tooltip: 'Reject',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 12),
            const Text('All Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: supabase
                    .from('bookings')
                    .select()
                    .order('created_at', ascending: false)
                    .limit(50),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final list = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final b = list[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.receipt, color: MyApp.primaryColor),
                        title: Text('${b['booking_type']} #${b['id']}  —  ৳${b['total_price']}'),
                        subtitle: Text('Status: ${b['status']}  •  ${b['created_at'].toString().substring(0, 10)}'),
                        trailing: b['status'] == 'pending'
                            ? TextButton(
                                onPressed: () async {
                                  await supabase
                                      .from('bookings')
                                      .update({'status': 'confirmed'})
                                      .eq('id', b['id']);
                                  setState(() {});
                                },
                                child: Text('Confirm', style: TextStyle(color: MyApp.secondaryColor)))
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}