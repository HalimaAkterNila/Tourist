import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isAdmin      = false;
  bool _loading      = true;
  int  _bookings     = 0;
  int  _users        = 0;
  int  _places       = 0;

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
        // Fetch summary counts
        final bookings = await supabase.from('bookings').select('id');
        final users    = await supabase.from('profiles').select('id');
        final places   = await supabase.from('places').select('id');
        setState(() {
          _isAdmin  = true;
          _bookings = (bookings as List).length;
          _users    = (users    as List).length;
          _places   = (places   as List).length;
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
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
              Text('Admin access required.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
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
            const Text('Overview',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _statCard('Total Bookings', _bookings, Icons.book,
                    Colors.blue),
                const SizedBox(width: 12),
                _statCard('Total Users', _users, Icons.people,
                    Colors.green),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _statCard('Total Places', _places, Icons.place,
                    MyApp.primaryColor),
              ],
            ),
            const SizedBox(height: 24),
            const Text('All Bookings',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: supabase
                    .from('bookings')
                    .select()
                    .order('created_at', ascending: false)
                    .limit(50),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final list = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final b = list[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.receipt,
                            color: MyApp.primaryColor),
                        title: Text(
                            '${b['booking_type']} #${b['id']}  —  ৳${b['total_price']}'),
                        subtitle: Text(
                            'Status: ${b['status']}  •  ${b['created_at'].toString().substring(0, 10)}'),
                        trailing: b['status'] == 'pending'
                            ? TextButton(
                                onPressed: () async {
                                  await supabase
                                      .from('bookings')
                                      .update({'status': 'confirmed'})
                                      .eq('id', b['id']);
                                  setState(() {});
                                },
                                child: const Text('Confirm',
                                    style: TextStyle(
                                        color: Colors.green)))
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  Text('$value',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}