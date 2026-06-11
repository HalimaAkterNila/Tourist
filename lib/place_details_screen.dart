import 'package:flutter/material.dart';
import 'main.dart';

class PlaceDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> place;
  const PlaceDetailsScreen({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(place['name'] ?? 'Place Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or placeholder
            place['image_url'] != null
                ? Image.network(
                    place['image_url'],
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: double.infinity,
                    height: 180,
                    color: MyApp.primaryColor.withOpacity(0.15),
                    child: const Icon(Icons.landscape,
                        size: 80, color: MyApp.primaryColor),
                  ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  if (place['category'] != null)
                    Chip(
                      label: Text(place['category'],
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor: MyApp.primaryColor,
                    ),
                  const SizedBox(height: 8),
                  Text(
                    place['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(place['division'] ?? '',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (place['description'] != null)
                    Text(
                      place['description'],
                      style: const TextStyle(fontSize: 15, height: 1.6),
                    ),
                  const SizedBox(height: 24),
                  // Coordinates if available
                  if (place['latitude'] != null &&
                      place['longitude'] != null) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.map, color: MyApp.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Lat: ${place['latitude']}  Lng: ${place['longitude']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}