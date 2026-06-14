import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';

class AddPlaceSuggestionScreen extends StatefulWidget {
  final String division;
  const AddPlaceSuggestionScreen({super.key, required this.division});

  @override
  State<AddPlaceSuggestionScreen> createState() => _AddPlaceSuggestionScreenState();
}

class _AddPlaceSuggestionScreenState extends State<AddPlaceSuggestionScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submitSuggestion() async {
    final name = _nameController.text.trim();
    final description = _descController.text.trim();
    final category = _categoryController.text.trim();

    if (name.isEmpty) {
      _showError('Place name is required');
      return;
    }

    setState(() => _loading = true);
    final user = supabase.auth.currentUser;
    if (user == null) {
      _showError('You must be logged in');
      setState(() => _loading = false);
      return;
    }

    try {
      await supabase.from('place_suggestions').insert({
        'division': widget.division,
        'name': name,
        'description': description.isEmpty ? null : description,
        'category': category.isEmpty ? null : category,
        'suggested_by': user.id,
        'status': 'pending',
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showError('Failed to submit: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suggest a New Place')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Division: ${widget.division}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Place Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Category (e.g., Beach, Historical, Forest)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submitSuggestion,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Suggestion'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}