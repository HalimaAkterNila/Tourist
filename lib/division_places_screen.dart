import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';
import 'place_details_screen.dart';

class DivisionPlacesScreen extends StatefulWidget {
  final String divisionName;
  const DivisionPlacesScreen({super.key, required this.divisionName});

  @override
  State<DivisionPlacesScreen> createState() => _DivisionPlacesScreenState();
}

class _DivisionPlacesScreenState extends State<DivisionPlacesScreen> {
  late Future<List<Map<String, dynamic>>> _placesFuture;

  @override
  void initState() {
    super.initState();
    _placesFuture = supabase
        .from('places')
        .select()
        .eq('division', widget.divisionName)
        .order('name');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.divisionName} Places')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _placesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final places = snapshot.data ?? [];
          if (places.isEmpty) {
            return const Center(child: Text('No places found for this division.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: places.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final place = places[index];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: MyApp.primaryColor,
                    child: Text(
                      place['name'][0],
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(place['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (place['category'] != null)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: MyApp.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            place['category'],
                            style: TextStyle(
                                fontSize: 11, color: MyApp.primaryColor),
                          ),
                        ),
                      if (place['description'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            place['description'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PlaceDetailsScreen(place: place)),
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