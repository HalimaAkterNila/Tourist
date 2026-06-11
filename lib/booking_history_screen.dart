import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  late Future<List<Map<String, dynamic>>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final user = supabase.auth.currentUser;
    if (user == null) {
      _bookingsFuture = Future.value([]);
      return;
    }
    _bookingsFuture = supabase
        .from('bookings')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
  }

  Future<void> _cancel(int bookingId) async {
    try {
      await supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId);
      setState(() => _load());
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Booking cancelled.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':  return Colors.green;
      case 'cancelled':  return Colors.red;
      default:           return Colors.orange;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'hotel':      return Icons.hotel;
      case 'transport':  return Icons.directions_bus;
      case 'tour_guide': return Icons.person_pin;
      default:           return Icons.book;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking History')),
        body: const Center(child: Text('Please log in to view bookings.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Booking History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final bookings = snapshot.data ?? [];
          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No bookings yet.'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, i) {
              final b = bookings[i];
              final date = b['travel_date'] ?? b['check_in'] ?? '';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: MyApp.primaryColor.withOpacity(0.15),
                    child: Icon(_typeIcon(b['booking_type']),
                        color: MyApp.primaryColor),
                  ),
                  title: Text(
                    '${b['booking_type'].toString().replaceAll('_', ' ').toUpperCase()}  #${b['id']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (date.isNotEmpty) Text('Date: $date'),
                      Text('Total: ৳${b['total_price']}'),
                      Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(b['status'])
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              b['status'].toUpperCase(),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _statusColor(b['status']),
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              b['payment_status'].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: b['status'] == 'pending'
                      ? TextButton(
                          onPressed: () => _cancel(b['id']),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.red)),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}