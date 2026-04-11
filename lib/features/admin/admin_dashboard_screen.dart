import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/bus.dart';
import '../../models/bus_location.dart';
import '../../models/bus_route.dart';
import '../../models/bus_schedule.dart';
import '../../models/geo_point.dart';
import '../../models/notice.dart';
import '../../models/student.dart';
import 'route_picker_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _firestore = FirestoreService();
  _AdminSection _section = _AdminSection.notices;
  bool _busy = false;

  Future<bool> _runAdminAction(
    Future<void> Function() action,
    String successMsg,
  ) async {
    if (_busy) {
      return false;
    }

    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg)),
      );
      return true;
    } catch (e) {
      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<bool> _confirmDelete(String label) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Delete $label?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC62828),
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<RouteSelectionResult?> _pickRouteFromMap([
    List<GeoPointData> initialCoordinates = const [],
  ]) {
    return Navigator.of(context).push<RouteSelectionResult>(
      MaterialPageRoute(
        builder: (_) =>
            RoutePickerScreen(initialCoordinates: initialCoordinates),
      ),
    );
  }

  GeoPointData _pointFrom(String latText, String lngText, String label) {
    final lat = double.tryParse(latText.trim());
    final lng = double.tryParse(lngText.trim());
    if (lat == null || lng == null) {
      throw Exception('Invalid $label coordinates');
    }
    return GeoPointData(lat: lat, lng: lng);
  }

  List<GeoPointData> _parseCoordinates(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return const [];
    }

    final points = <GeoPointData>[];
    for (final pair in value.split(';')) {
      final parts = pair.split(',');
      if (parts.length != 2) {
        throw Exception('Route points must be in "lat,lng;lat,lng" format');
      }
      points.add(_pointFrom(parts[0], parts[1], 'route point'));
    }
    return points;
  }

  String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _openCreateSheet() async {
    switch (_section) {
      case _AdminSection.users:
        await _showUserForm();
        break;
      case _AdminSection.notices:
        await _showNoticeForm();
        break;
      case _AdminSection.buses:
        await _showBusForm();
        break;
      case _AdminSection.routes:
        await _showRouteForm();
        break;
      case _AdminSection.schedules:
        await _showScheduleForm();
        break;
      case _AdminSection.locations:
        await _showLocationForm();
        break;
    }
  }

  Future<void> _showUserForm({Student? existing}) {
    final uid = TextEditingController(text: existing?.uid ?? '');
    final name = TextEditingController(text: existing?.name ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final kuetId = TextEditingController(text: existing?.kuetId ?? '');
    final department = TextEditingController(text: existing?.department ?? '');
    final batch = TextEditingController(text: existing?.batch ?? '');
    final bloodGroup = TextEditingController(text: existing?.bloodGroup ?? '');
    final hometown = TextEditingController(text: existing?.hometown ?? '');
    final phoneNumber =
        TextEditingController(text: existing?.phoneNumber ?? '');
    final photoUrl = TextEditingController(text: existing?.photoUrl ?? '');
    var role = existing?.role ?? 'student';

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _editorSheet(
              title: existing == null ? 'Create User' : 'Update User',
              child: Column(
                children: [
                  _input(uid, 'User UID', enabled: existing == null),
                  const SizedBox(height: 10),
                  _input(name, 'Name'),
                  const SizedBox(height: 10),
                  _input(email, 'Email'),
                  const SizedBox(height: 10),
                  _input(kuetId, 'KUET ID'),
                  const SizedBox(height: 10),
                  _input(department, 'Department'),
                  const SizedBox(height: 10),
                  _input(batch, 'Batch'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: role,
                    decoration: _decoration('Role'),
                    items: const [
                      DropdownMenuItem(
                          value: 'student', child: Text('student')),
                      DropdownMenuItem(value: 'admin', child: Text('admin')),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) =>
                            setModalState(() => role = value ?? 'student'),
                  ),
                  const SizedBox(height: 10),
                  _input(bloodGroup, 'Blood Group (optional)'),
                  const SizedBox(height: 10),
                  _input(hometown, 'Hometown (optional)'),
                  const SizedBox(height: 10),
                  _input(phoneNumber, 'Phone Number (optional)'),
                  const SizedBox(height: 10),
                  _input(photoUrl, 'Photo URL (optional)'),
                  const SizedBox(height: 14),
                  _formActions(
                    sheetContext: sheetContext,
                    saveLabel: existing == null ? 'Create' : 'Update',
                    onSave: () async {
                      final targetUid = uid.text.trim();
                      if (targetUid.isEmpty ||
                          name.text.trim().isEmpty ||
                          email.text.trim().isEmpty) {
                        throw Exception('UID, name, and email are required');
                      }

                      final user = Student(
                        uid: targetUid,
                        name: name.text.trim(),
                        email: email.text.trim(),
                        kuetId: kuetId.text.trim(),
                        department: department.text.trim(),
                        batch: batch.text.trim(),
                        role: role,
                        bloodGroup: _nullIfBlank(bloodGroup.text),
                        hometown: _nullIfBlank(hometown.text),
                        phoneNumber: _nullIfBlank(phoneNumber.text),
                        photoUrl: _nullIfBlank(photoUrl.text),
                        photoPath: existing?.photoPath,
                        createdAt: existing?.createdAt ?? DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      final ok = await _runAdminAction(
                        () => _firestore.upsertStudent(user),
                        existing == null ? 'User created' : 'User updated',
                      );
                      if (ok && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showNoticeForm({Notice? existing}) {
    final title = TextEditingController(text: existing?.title ?? '');
    final body = TextEditingController(text: existing?.body ?? '');
    var tag = existing?.tag ?? 'INFO';

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _editorSheet(
              title: existing == null ? 'Create Notice' : 'Update Notice',
              child: Column(
                children: [
                  _input(title, 'Notice title'),
                  const SizedBox(height: 10),
                  _input(body, 'Notice body', maxLines: 4),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: tag,
                    decoration: _decoration('Tag'),
                    items: const [
                      DropdownMenuItem(value: 'INFO', child: Text('INFO')),
                      DropdownMenuItem(value: 'ALERT', child: Text('ALERT')),
                      DropdownMenuItem(value: 'EVENT', child: Text('EVENT')),
                    ],
                    onChanged: _busy
                        ? null
                        : (value) => setModalState(() => tag = value ?? 'INFO'),
                  ),
                  const SizedBox(height: 14),
                  _formActions(
                    sheetContext: sheetContext,
                    saveLabel: existing == null ? 'Create' : 'Update',
                    onSave: () async {
                      if (title.text.trim().isEmpty ||
                          body.text.trim().isEmpty) {
                        throw Exception('Title and body are required');
                      }

                      final notice = Notice(
                        id: existing?.id,
                        title: title.text.trim(),
                        body: body.text.trim(),
                        tag: tag,
                        priority: existing?.priority,
                        createdBy: existing?.createdBy ??
                            FirebaseAuth.instance.currentUser?.uid,
                        createdAt: existing?.createdAt ?? DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      final ok = await _runAdminAction(
                        () => _firestore.upsertNotice(notice),
                        existing == null ? 'Notice created' : 'Notice updated',
                      );
                      if (ok && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showBusForm({Bus? existing}) {
    final busNumber = TextEditingController(text: existing?.busNumber ?? '');
    final busName = TextEditingController(text: existing?.busName ?? '');
    final plateNumber =
        TextEditingController(text: existing?.plateNumber ?? '');
    final driverId = TextEditingController(text: existing?.driverId ?? '');

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _editorSheet(
          title: existing == null ? 'Create Bus' : 'Update Bus',
          child: Column(
            children: [
              _input(busNumber, 'Bus Number'),
              const SizedBox(height: 10),
              _input(busName, 'Bus Name'),
              const SizedBox(height: 10),
              _input(plateNumber, 'Plate Number (optional)'),
              const SizedBox(height: 10),
              _input(driverId, 'Driver ID (optional)'),
              const SizedBox(height: 14),
              _formActions(
                sheetContext: sheetContext,
                saveLabel: existing == null ? 'Create' : 'Update',
                onSave: () async {
                  if (busNumber.text.trim().isEmpty ||
                      busName.text.trim().isEmpty) {
                    throw Exception('Bus number and bus name are required');
                  }

                  final bus = Bus(
                    id: existing?.id,
                    busNumber: busNumber.text.trim(),
                    busName: busName.text.trim(),
                    plateNumber: _nullIfBlank(plateNumber.text),
                    driverId: _nullIfBlank(driverId.text),
                    createdAt: existing?.createdAt ?? DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  final ok = await _runAdminAction(
                    () => _firestore.upsertBus(bus),
                    existing == null ? 'Bus created' : 'Bus updated',
                  );
                  if (ok && sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRouteForm({BusRoute? existing}) {
    final routeName = TextEditingController(text: existing?.routeName ?? '');
    final originLat = TextEditingController(
      text: existing == null ? '' : existing.origin.lat.toStringAsFixed(6),
    );
    final originLng = TextEditingController(
      text: existing == null ? '' : existing.origin.lng.toStringAsFixed(6),
    );
    final destLat = TextEditingController(
      text: existing == null ? '' : existing.destination.lat.toStringAsFixed(6),
    );
    final destLng = TextEditingController(
      text: existing == null ? '' : existing.destination.lng.toStringAsFixed(6),
    );
    final routeCoords = TextEditingController(
      text: existing == null
          ? ''
          : existing.coordinates
              .map((e) =>
                  '${e.lat.toStringAsFixed(6)},${e.lng.toStringAsFixed(6)}')
              .join(';'),
    );

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _editorSheet(
              title: existing == null ? 'Create Route' : 'Update Route',
              child: Column(
                children: [
                  _input(routeName, 'Route Name'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _input(
                          originLat,
                          'Origin lat',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _input(
                          originLng,
                          'Origin lng',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _input(
                          destLat,
                          'Destination lat',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _input(
                          destLng,
                          'Destination lng',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _input(routeCoords, 'Route coords: lat,lng;lat,lng',
                      maxLines: 4),
                  const SizedBox(height: 10),
                  _actionButton(
                    'Select Road From Map',
                    () async {
                      final result = await _pickRouteFromMap(
                          existing?.coordinates ?? const []);
                      if (result == null) {
                        return;
                      }
                      originLat.text = result.origin.lat.toStringAsFixed(6);
                      originLng.text = result.origin.lng.toStringAsFixed(6);
                      destLat.text = result.destination.lat.toStringAsFixed(6);
                      destLng.text = result.destination.lng.toStringAsFixed(6);
                      routeCoords.text = result.coordinates
                          .map((e) =>
                              '${e.lat.toStringAsFixed(6)},${e.lng.toStringAsFixed(6)}')
                          .join(';');
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 14),
                  _formActions(
                    sheetContext: sheetContext,
                    saveLabel: existing == null ? 'Create' : 'Update',
                    onSave: () async {
                      if (routeName.text.trim().isEmpty) {
                        throw Exception('Route name is required');
                      }

                      final route = BusRoute(
                        id: existing?.id,
                        routeName: routeName.text.trim(),
                        origin: _pointFrom(
                            originLat.text, originLng.text, 'origin'),
                        destination: _pointFrom(
                            destLat.text, destLng.text, 'destination'),
                        coordinates: _parseCoordinates(routeCoords.text),
                        createdAt: existing?.createdAt ?? DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      final ok = await _runAdminAction(
                        () => _firestore.upsertRoute(route),
                        existing == null ? 'Route created' : 'Route updated',
                      );
                      if (ok && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showScheduleForm({BusSchedule? existing}) {
    final time = TextEditingController(text: existing?.time ?? '');
    String? selectedRouteId = existing?.routeId;
    String? selectedBusId = existing?.busId;
    final selectedDays = <String>{
      ...(existing?.daysOfWeek ?? const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu'])
    };
    var period = existing?.period ?? 'AM';
    var isActive = existing?.isActive ?? true;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _editorSheet(
              title: existing == null ? 'Create Schedule' : 'Update Schedule',
              child: Column(
                children: [
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('routes')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? const [];
                      final selectedValue =
                          selectedRouteId != null &&
                                  selectedRouteId!.isNotEmpty &&
                                  docs.any((d) => d.id == selectedRouteId)
                              ? selectedRouteId
                              : null;
                      return DropdownButtonFormField<String>(
                        value: selectedValue,
                        decoration: _decoration('Route Name'),
                        items: docs.map((doc) {
                          final routeName =
                              (doc.data()['routeName'] as String?)?.trim() ??
                                  '';
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(routeName.isEmpty
                                ? 'Unnamed Route'
                                : routeName),
                          );
                        }).toList(),
                        onChanged: _busy
                            ? null
                            : (value) =>
                                setModalState(() => selectedRouteId = value),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('buses')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? const [];
                      final selectedValue =
                          selectedBusId != null &&
                                  selectedBusId!.isNotEmpty &&
                                  docs.any((d) => d.id == selectedBusId)
                              ? selectedBusId
                              : null;
                      return DropdownButtonFormField<String>(
                        value: selectedValue,
                        decoration: _decoration('Bus Name'),
                        items: docs.map((doc) {
                          final data = doc.data();
                          final busName =
                              (data['busName'] as String?)?.trim() ?? '';
                          final busNumber =
                              (data['busNumber'] as String?)?.trim() ?? '';
                          final label = busName.isEmpty
                              ? 'Unnamed Bus'
                              : busNumber.isEmpty
                                  ? busName
                                  : '$busName ($busNumber)';
                          return DropdownMenuItem<String>(
                            value: doc.id,
                            child: Text(label),
                          );
                        }).toList(),
                        onChanged: _busy
                            ? null
                            : (value) =>
                                setModalState(() => selectedBusId = value),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _input(time, 'Time (e.g. 8:30)')),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: period,
                          decoration: _decoration('Period'),
                          items: const [
                            DropdownMenuItem(value: 'AM', child: Text('AM')),
                            DropdownMenuItem(value: 'PM', child: Text('PM')),
                          ],
                          onChanged: _busy
                              ? null
                              : (value) =>
                                  setModalState(() => period = value ?? 'AM'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Days of Week',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                      .map(
                    (day) => CheckboxListTile(
                      value: selectedDays.contains(day),
                      onChanged: _busy
                          ? null
                          : (checked) {
                              setModalState(() {
                                if (checked ?? false) {
                                  selectedDays.add(day);
                                } else {
                                  selectedDays.remove(day);
                                }
                              });
                            },
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(day),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: isActive,
                    onChanged: _busy
                        ? null
                        : (value) => setModalState(() => isActive = value),
                    title: const Text('Schedule Active'),
                  ),
                  const SizedBox(height: 14),
                  _formActions(
                    sheetContext: sheetContext,
                    saveLabel: existing == null ? 'Create' : 'Update',
                    onSave: () async {
                      final normalizedDays = const [
                        'Sun',
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat'
                      ].where(selectedDays.contains).toList();
                      if ((selectedRouteId == null ||
                              selectedRouteId!.isEmpty) ||
                          (selectedBusId == null || selectedBusId!.isEmpty) ||
                          time.text.trim().isEmpty ||
                          normalizedDays.isEmpty) {
                        throw Exception(
                            'Route, Bus, time and at least one day are required');
                      }

                      final schedule = BusSchedule(
                        id: existing?.id,
                        routeId: selectedRouteId!,
                        busId: selectedBusId!,
                        time: time.text.trim(),
                        period: period,
                        daysOfWeek: normalizedDays,
                        isActive: isActive,
                        createdAt: existing?.createdAt ?? DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      final ok = await _runAdminAction(
                        () => _firestore.upsertSchedule(schedule),
                        existing == null
                            ? 'Schedule created'
                            : 'Schedule updated',
                      );
                      if (ok && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showLocationForm({BusLocation? existing}) {
    final busId = TextEditingController(text: existing?.busId ?? '');
    final lat = TextEditingController(
      text: existing == null ? '' : existing.position.lat.toStringAsFixed(6),
    );
    final lng = TextEditingController(
      text: existing == null ? '' : existing.position.lng.toStringAsFixed(6),
    );
    final heading =
        TextEditingController(text: existing?.heading?.toString() ?? '');
    var isMoving = existing?.isMoving ?? true;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _editorSheet(
              title: existing == null ? 'Create Location' : 'Update Location',
              child: Column(
                children: [
                  _input(busId, 'Bus ID', enabled: existing == null),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _input(
                          lat,
                          'Latitude',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _input(
                          lng,
                          'Longitude',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _input(
                    heading,
                    'Heading (optional)',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: isMoving,
                    onChanged: _busy
                        ? null
                        : (value) => setModalState(() => isMoving = value),
                    title: const Text('Bus is moving'),
                  ),
                  const SizedBox(height: 14),
                  _formActions(
                    sheetContext: sheetContext,
                    saveLabel: existing == null ? 'Create' : 'Update',
                    onSave: () async {
                      if (busId.text.trim().isEmpty) {
                        throw Exception('Bus ID is required');
                      }
                      final headingValue = heading.text.trim().isEmpty
                          ? null
                          : double.tryParse(heading.text.trim());
                      if (heading.text.trim().isNotEmpty &&
                          headingValue == null) {
                        throw Exception('Heading must be a valid number');
                      }

                      final location = BusLocation(
                        busId: busId.text.trim(),
                        position: _pointFrom(lat.text, lng.text, 'location'),
                        heading: headingValue,
                        isMoving: isMoving,
                        updatedAt: DateTime.now(),
                      );

                      final ok = await _runAdminAction(
                        () => _firestore.updateBusLocation(location),
                        existing == null
                            ? 'Location created'
                            : 'Location updated',
                      );
                      if (ok && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeData.of(context);

    return Scaffold(
      backgroundColor: theme.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _AdminSection.values.map((section) {
                        final selected = section == _section;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _collectionTab(theme, section, selected),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSectionBody(theme),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: _actionButton(
              'Create ${_section.singularLabel}', _openCreateSheet),
        ),
      ),
    );
  }

  Widget _buildSectionBody(AppThemeData theme) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(_section.collectionName)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Failed to load ${_section.label}'));
        }

        final docs = snapshot.data?.docs ?? const [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No ${_section.label.toLowerCase()} found.',
              style: TextStyle(color: theme.subText),
            ),
          );
        }

        if (_section == _AdminSection.schedules) {
          return StreamBuilder<List<Bus>>(
            stream: _firestore.watchBuses(),
            builder: (context, busSnapshot) {
              final buses = busSnapshot.data ?? const <Bus>[];
              final busLabelById = <String, String>{};
              for (final bus in buses) {
                final id = bus.id;
                if (id == null || id.isEmpty) {
                  continue;
                }
                final label = bus.busName.trim().isNotEmpty
                    ? bus.busName.trim()
                    : bus.busNumber.trim();
                if (label.isNotEmpty) {
                  busLabelById[id] = label;
                }
              }

              return StreamBuilder<List<BusRoute>>(
                stream: _firestore.watchRoutes(),
                builder: (context, routeSnapshot) {
                  final routes = routeSnapshot.data ?? const <BusRoute>[];
                  final routeLabelById = <String, String>{};
                  for (final route in routes) {
                    final id = route.id;
                    if (id == null || id.isEmpty) {
                      continue;
                    }
                    final label = route.routeName.trim();
                    if (label.isNotEmpty) {
                      routeLabelById[id] = label;
                    }
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final schedule =
                          BusSchedule.fromJson(doc.data(), id: doc.id);
                      final routeLabel =
                          routeLabelById[schedule.routeId] ?? 'Unknown Route';
                      final busLabel =
                          busLabelById[schedule.busId] ?? 'Unknown Bus';

                      return _recordCard(
                        theme,
                        title: '${schedule.time} ${schedule.period}',
                        docId: doc.id,
                        lines: [
                          'Route: $routeLabel',
                          'Bus: $busLabel',
                          'Days: ${schedule.daysOfWeek.join(', ')}',
                          'Active: ${schedule.isActive ? 'Yes' : 'No'}',
                        ],
                        onEdit: () => _showScheduleForm(existing: schedule),
                        onDelete: () async {
                          if (!await _confirmDelete('schedule')) {
                            return;
                          }
                          await _runAdminAction(
                              () => _firestore.deleteSchedule(doc.id),
                              'Schedule deleted');
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final doc = docs[index];
            switch (_section) {
              case _AdminSection.users:
                final user = Student.fromJson(doc.data(), uid: doc.id);
                return _recordCard(
                  theme,
                  title: user.name,
                  docId: doc.id,
                  lines: [
                    'Email: ${user.email}',
                    'Role: ${user.role}',
                    'Department: ${user.department.isEmpty ? 'N/A' : user.department}',
                    'Batch: ${user.batch.isEmpty ? 'N/A' : user.batch}',
                  ],
                  onEdit: () => _showUserForm(existing: user),
                  onDelete: () async {
                    if (!await _confirmDelete('user document')) {
                      return;
                    }
                    await _runAdminAction(
                        () => _firestore.deleteUser(doc.id), 'User deleted');
                  },
                );
              case _AdminSection.notices:
                final notice = Notice.fromJson(doc.data(), id: doc.id);
                return _recordCard(
                  theme,
                  title: notice.title,
                  docId: doc.id,
                  lines: ['Tag: ${notice.tag}', notice.body],
                  onEdit: () => _showNoticeForm(existing: notice),
                  onDelete: () async {
                    if (!await _confirmDelete('notice')) {
                      return;
                    }
                    await _runAdminAction(() => _firestore.deleteNotice(doc.id),
                        'Notice deleted');
                  },
                );
              case _AdminSection.buses:
                final bus = Bus.fromJson(doc.data(), id: doc.id);
                return _recordCard(
                  theme,
                  title: '${bus.busNumber} · ${bus.busName}',
                  docId: doc.id,
                  lines: [
                    'Plate: ${bus.plateNumber ?? 'N/A'}',
                    'Driver ID: ${bus.driverId ?? 'N/A'}',
                  ],
                  onEdit: () => _showBusForm(existing: bus),
                  onDelete: () async {
                    if (!await _confirmDelete('bus')) {
                      return;
                    }
                    await _runAdminAction(
                        () => _firestore.deleteBus(doc.id), 'Bus deleted');
                  },
                );
              case _AdminSection.routes:
                final route = BusRoute.fromJson(doc.data(), id: doc.id);
                return _recordCard(
                  theme,
                  title: route.routeName.isEmpty
                      ? 'Unnamed Route'
                      : route.routeName,
                  docId: doc.id,
                  lines: [
                    'Origin: ${route.origin.lat.toStringAsFixed(5)}, ${route.origin.lng.toStringAsFixed(5)}',
                    'Destination: ${route.destination.lat.toStringAsFixed(5)}, ${route.destination.lng.toStringAsFixed(5)}',
                    'Points: ${route.coordinates.length}',
                  ],
                  onEdit: () => _showRouteForm(existing: route),
                  onDelete: () async {
                    if (!await _confirmDelete('route')) {
                      return;
                    }
                    await _runAdminAction(
                        () => _firestore.deleteRoute(doc.id), 'Route deleted');
                  },
                );
              case _AdminSection.schedules:
                // Handled above, so we can resolve route/bus names.
                final schedule = BusSchedule.fromJson(doc.data(), id: doc.id);
                return _recordCard(
                  theme,
                  title: '${schedule.time} ${schedule.period}',
                  docId: doc.id,
                  lines: [
                    'Route: ${schedule.routeId}',
                    'Bus: ${schedule.busId}',
                    'Days: ${schedule.daysOfWeek.join(', ')}',
                    'Active: ${schedule.isActive ? 'Yes' : 'No'}',
                  ],
                  onEdit: () => _showScheduleForm(existing: schedule),
                  onDelete: () async {
                    if (!await _confirmDelete('schedule')) {
                      return;
                    }
                    await _runAdminAction(
                        () => _firestore.deleteSchedule(doc.id),
                        'Schedule deleted');
                  },
                );
              case _AdminSection.locations:
                final location =
                    BusLocation.fromJson(doc.data(), busId: doc.id);
                return _recordCard(
                  theme,
                  title: 'Bus ${location.busId}',
                  docId: doc.id,
                  lines: [
                    'Position: ${location.position.lat.toStringAsFixed(5)}, ${location.position.lng.toStringAsFixed(5)}',
                    'Heading: ${location.heading?.toStringAsFixed(1) ?? 'N/A'}',
                    'Moving: ${location.isMoving ? 'Yes' : 'No'}',
                  ],
                  onEdit: () => _showLocationForm(existing: location),
                  onDelete: () async {
                    if (!await _confirmDelete('location')) {
                      return;
                    }
                    await _runAdminAction(
                        () => _firestore.deleteBusLocation(doc.id),
                        'Location deleted');
                  },
                );
            }
          },
        );
      },
    );
  }

  Widget _collectionTab(
    AppThemeData theme,
    _AdminSection section,
    bool selected,
  ) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(section.collectionName)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _section = section),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : theme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.primary : theme.border,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Text(
                    section.label,
                    style: TextStyle(
                      color: selected ? AppColors.primary : theme.text,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Positioned(
                  top: -8,
                  right: -6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : theme.text.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _recordCard(
    AppThemeData theme, {
    required String title,
    required String docId,
    required List<String> lines,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    Widget iconAction({
      required IconData icon,
      required VoidCallback onTap,
      required Color background,
      required Color iconColor,
      required String tooltip,
    }) {
      return Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: _busy ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.border),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.border),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    docId,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.subText, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              iconAction(
                icon: Icons.edit_rounded,
                onTap: onEdit,
                tooltip: 'Update',
                background: theme.surfaceDeep,
                iconColor: theme.text,
              ),
              const SizedBox(width: 8),
              iconAction(
                icon: Icons.delete_outline_rounded,
                onTap: onDelete,
                tooltip: 'Delete',
                background: const Color(0xFFFDECEC),
                iconColor: const Color(0xFFC62828),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: TextStyle(color: theme.subText, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editorSheet({required String title, required Widget child}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _formActions({
    required Future<void> Function() onSave,
    required String saveLabel,
    required BuildContext sheetContext,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _busy ? null : () => Navigator.of(sheetContext).pop(),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(saveLabel, () async => onSave()),
        ),
      ],
    );
  }

  Widget _input(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled && !_busy,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _decoration(hint),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  Widget _actionButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label),
      ),
    );
  }

  Widget _dangerButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC62828),
          disabledBackgroundColor:
              const Color(0xFFC62828).withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label),
      ),
    );
  }
}

enum _AdminSection {
  users,
  notices,
  buses,
  routes,
  schedules,
  locations,
}

extension on _AdminSection {
  String get label {
    switch (this) {
      case _AdminSection.users:
        return 'Users';
      case _AdminSection.notices:
        return 'Notices';
      case _AdminSection.buses:
        return 'Buses';
      case _AdminSection.routes:
        return 'Routes';
      case _AdminSection.schedules:
        return 'Schedules';
      case _AdminSection.locations:
        return 'Bus Locations';
    }
  }

  String get singularLabel {
    switch (this) {
      case _AdminSection.users:
        return 'User';
      case _AdminSection.notices:
        return 'Notice';
      case _AdminSection.buses:
        return 'Bus';
      case _AdminSection.routes:
        return 'Route';
      case _AdminSection.schedules:
        return 'Schedule';
      case _AdminSection.locations:
        return 'Location';
    }
  }

  String get collectionName {
    switch (this) {
      case _AdminSection.users:
        return 'users';
      case _AdminSection.notices:
        return 'notices';
      case _AdminSection.buses:
        return 'buses';
      case _AdminSection.routes:
        return 'routes';
      case _AdminSection.schedules:
        return 'schedules';
      case _AdminSection.locations:
        return 'bus_locations';
    }
  }
}
