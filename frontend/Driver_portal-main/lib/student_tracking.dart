import 'package:flutter/material.dart';

class StudentTrackingScreen extends StatefulWidget {
  const StudentTrackingScreen({super.key});

  @override
  State<StudentTrackingScreen> createState() => _StudentTrackingScreenState();
}

class _StudentTrackingScreenState extends State<StudentTrackingScreen> {
  // Manage route stops as a list of TextEditingControllers so every stop has a text field.
  final List<TextEditingController> _stopControllers = [];

  @override
  void initState() {
    super.initState();
    // start with two stops by default
    _addStop();
    _addStop();
  }

  @override
  void dispose() {
    for (final c in _stopControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addStop() {
    setState(() => _stopControllers.add(TextEditingController()));
  }

  void _removeStop(int index) {
    setState(() {
      _stopControllers[index].dispose();
      _stopControllers.removeAt(index);
    });
  }

  Future<void> _showRouteStopsPanel() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SizedBox(
            height: 420,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Text('Route Stops', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        onPressed: _addStop,
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Add stop',
                      )
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _stopControllers.length,
                    itemBuilder: (context, index) {
                      final ctrl = _stopControllers[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: ctrl,
                                decoration: InputDecoration(
                                  labelText: 'Stop ${index + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _removeStop(index),
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              tooltip: 'Remove',
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // collect stops values
                            final stops = _stopControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
                            Navigator.of(context).pop(stops);
                          },
                          child: const Text('Save Stops'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onCreatePressed() {
    // Open create bottom sheet or navigate to a create screen. For now show a dialog.
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create'),
        content: const Text('Create action tapped. Use this to add a new route or stop group.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Tracking'),
        actions: [
          // Create button on the right side
          IconButton(
            icon: const Icon(Icons.create_outlined),
            tooltip: 'Create',
            onPressed: _onCreatePressed,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: _showRouteStopsPanel,
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Route Stops'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tap "Route Stops" to add/edit stops. Each stop will have its own text field.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.green),
            ),
            // Additional UI for student tracking (map/list) can go here.
          ],
        ),
      ),
    );
  }
}