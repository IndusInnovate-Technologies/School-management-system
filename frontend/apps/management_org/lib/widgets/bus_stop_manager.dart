import 'package:flutter/material.dart';
import 'package:core/api/api_service.dart';
import 'package:core/api/endpoints.dart';
import 'student_list_dialog.dart';

/// Model for a bus stop
class BusStopModel {
  final String? stopId;
  final String stopName;
  final TimeOfDay stopTime;
  final int stopOrder;
  final String routeType; // 'morning' or 'afternoon'
  int studentCount;

  BusStopModel({
    this.stopId,
    required this.stopName,
    required this.stopTime,
    required this.stopOrder,
    required this.routeType,
    this.studentCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      if (stopId != null) 'stop_id': stopId,
      'stop_name': stopName,
      'stop_time': '${stopTime.hour.toString().padLeft(2, '0')}:${stopTime.minute.toString().padLeft(2, '0')}',
      'stop_order': stopOrder,
      'route_type': routeType,
    };
  }

  factory BusStopModel.fromJson(Map<String, dynamic> json) {
    final timeStr = json['stop_time'] as String? ?? '00:00';
    final timeParts = timeStr.split(':');
    return BusStopModel(
      stopId: json['stop_id']?.toString(),
      stopName: json['stop_name'] ?? '',
      stopTime: TimeOfDay(
        hour: int.tryParse(timeParts[0]) ?? 0,
        minute: int.tryParse(timeParts[1]) ?? 0,
      ),
      stopOrder: json['stop_order'] ?? 0,
      routeType: json['route_type'] ?? 'morning',
      studentCount: json['student_count'] ?? json['students']?.length ?? 0,
    );
  }
}

/// Reusable widget for managing bus stops
class BusStopManager extends StatefulWidget {
  final String? busId;
  final String routeType; // 'morning' or 'afternoon'
  final String routeTitle;
  final List<BusStopModel> initialStops;
  final Function(List<BusStopModel>) onStopsChanged;
  final bool isReadOnly; // If true, stops are view-only and cannot be edited

  const BusStopManager({
    super.key,
    this.busId,
    required this.routeType,
    required this.routeTitle,
    required this.initialStops,
    required this.onStopsChanged,
    this.isReadOnly = false,
  });

  @override
  State<BusStopManager> createState() => _BusStopManagerState();
}

class _BusStopManagerState extends State<BusStopManager> {
  late List<BusStopModel> _stops;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _stops = List.from(widget.initialStops);
  }

  @override
  void didUpdateWidget(BusStopManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update stops when initialStops change (for read-only mode)
    if (widget.initialStops != oldWidget.initialStops) {
      _stops = List.from(widget.initialStops);
    }
  }

  void _addStop() {
    showDialog(
      context: context,
      builder: (context) => _AddStopDialog(
        routeType: widget.routeType,
        nextOrder: _stops.length + 1,
        onSave: (stop) {
          setState(() {
            _stops.add(stop);
            _stops.sort((a, b) => a.stopOrder.compareTo(b.stopOrder));
          });
          widget.onStopsChanged(_stops);
        },
      ),
    );
  }

  void _editStop(BusStopModel stop, int index) {
    showDialog(
      context: context,
      builder: (context) => _AddStopDialog(
        routeType: widget.routeType,
        initialStop: stop,
        nextOrder: stop.stopOrder,
        onSave: (updatedStop) {
          setState(() {
            _stops[index] = updatedStop;
            _stops.sort((a, b) => a.stopOrder.compareTo(b.stopOrder));
          });
          widget.onStopsChanged(_stops);
        },
      ),
    );
  }

  void _deleteStop(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stop'),
        content: Text('Are you sure you want to delete ${_stops[index].stopName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _stops.removeAt(index);
                // Reorder remaining stops
                for (int i = 0; i < _stops.length; i++) {
                  _stops[i] = BusStopModel(
                    stopId: _stops[i].stopId,
                    stopName: _stops[i].stopName,
                    stopTime: _stops[i].stopTime,
                    stopOrder: i + 1,
                    routeType: _stops[i].routeType,
                    studentCount: _stops[i].studentCount,
                  );
                }
              });
              widget.onStopsChanged(_stops);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _viewStopStudents(BusStopModel stop) async {
    if (widget.busId == null || stop.stopId == null) {
      // For new stops, show empty list
      showDialog(
        context: context,
        builder: (context) => StudentListDialog(
          stopId: stop.stopId,
          stopName: stop.stopName,
          routeType: widget.routeType,
          busId: widget.busId,
        ),
      );
      return;
    }

    try {
      final response = await _apiService.get('${Endpoints.busStops}${stop.stopId}/students/');
      if (response.success && mounted) {
        final students = (response.data as List?) ?? [];
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => StudentListDialog(
              stopId: stop.stopId,
              stopName: stop.stopName,
              routeType: widget.routeType,
              busId: widget.busId,
              initialStudents: students,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading students: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.routeTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (!widget.isReadOnly)
              ElevatedButton.icon(
                onPressed: _addStop,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            if (widget.isReadOnly)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Auto-generated',
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 15),
        if (_stops.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'No stops added yet. Click "Add Stop" to add stops.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._stops.asMap().entries.map((entry) {
            final index = entry.key;
            final stop = entry.value;
            return _StopCard(
              stop: stop,
              isReadOnly: widget.isReadOnly,
              onTap: () => _viewStopStudents(stop),
              onEdit: () => _editStop(stop, index),
              onDelete: () => _deleteStop(index),
            );
          }),
      ],
    );
  }
}

class _StopCard extends StatelessWidget {
  final BusStopModel stop;
  final bool isReadOnly;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StopCard({
    required this.stop,
    this.isReadOnly = false,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${stop.stopOrder}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.stopName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          stop.stopTime.format(context),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Icon(Icons.people, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${stop.studentCount} students',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.visibility, color: Color(0xFF667EEA)),
                onPressed: onTap,
                tooltip: 'View Students',
              ),
              if (!isReadOnly) ...[
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFFFFD93D)),
                  onPressed: onEdit,
                  tooltip: 'Edit Stop',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete Stop',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddStopDialog extends StatefulWidget {
  final String routeType;
  final BusStopModel? initialStop;
  final int nextOrder;
  final Function(BusStopModel) onSave;

  const _AddStopDialog({
    required this.routeType,
    this.initialStop,
    required this.nextOrder,
    required this.onSave,
  });

  @override
  State<_AddStopDialog> createState() => _AddStopDialogState();
}

class _AddStopDialogState extends State<_AddStopDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  TimeOfDay? _selectedTime;
  int _order = 1;

  @override
  void initState() {
    super.initState();
    if (widget.initialStop != null) {
      _nameController.text = widget.initialStop!.stopName;
      _selectedTime = widget.initialStop!.stopTime;
      _order = widget.initialStop!.stopOrder;
    } else {
      _order = widget.nextOrder;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time')),
      );
      return;
    }

    final stop = BusStopModel(
      stopId: widget.initialStop?.stopId,
      stopName: _nameController.text.trim(),
      stopTime: _selectedTime!,
      stopOrder: _order,
      routeType: widget.routeType,
      studentCount: widget.initialStop?.studentCount ?? 0,
    );

    widget.onSave(stop);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialStop == null ? 'Add Stop' : 'Edit Stop'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Stop Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stop name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey[600]),
                      const SizedBox(width: 10),
                      Text(
                        _selectedTime == null
                            ? 'Select Time *'
                            : _selectedTime!.format(context),
                        style: TextStyle(
                          color: _selectedTime == null
                              ? Colors.grey[600]
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                initialValue: _order.toString(),
                decoration: const InputDecoration(
                  labelText: 'Stop Order *',
                  border: OutlineInputBorder(),
                  helperText: 'Order of stop in route (1, 2, 3, ...)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _order = int.tryParse(value) ?? _order;
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter stop order';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 1) {
                    return 'Please enter a valid order number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667EEA),
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

