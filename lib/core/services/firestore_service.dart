import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/bus.dart';
import '../../models/bus_location.dart';
import '../../models/bus_route.dart';
import '../../models/bus_schedule.dart';
import '../../models/notice.dart';
import '../../models/student.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _notices =>
      _db.collection('notices');
  CollectionReference<Map<String, dynamic>> get _buses =>
      _db.collection('buses');
  CollectionReference<Map<String, dynamic>> get _routes =>
      _db.collection('routes');
  CollectionReference<Map<String, dynamic>> get _schedules =>
      _db.collection('schedules');
  CollectionReference<Map<String, dynamic>> get _busLocations =>
      _db.collection('bus_locations');

  // Unique index collections (enforced via rules + transactions in this service).
  CollectionReference<Map<String, dynamic>> get _uniqueBusNumbers =>
      _db.collection('unique_bus_numbers');
  CollectionReference<Map<String, dynamic>> get _uniqueRouteNames =>
      _db.collection('unique_route_names');

  String _normalizeKey(String raw) {
    final lower = raw.trim().toLowerCase();
    final dashed = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final collapsed = dashed.replaceAll(RegExp(r'-{2,}'), '-');
    return collapsed.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Stream<List<Notice>> watchNotices() {
    return (() async* {
      final user = FirebaseAuth.instance.currentUser;
      try {
        await user?.getIdToken(true);
      } catch (_) {}
      yield* _notices.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => Notice.fromJson(doc.data(), id: doc.id))
              .toList());
    })();
  }

  Stream<List<BusSchedule>> watchSchedules() {
    return (() async* {
      final user = FirebaseAuth.instance.currentUser;
      try {
        await user?.getIdToken(true);
      } catch (_) {}
      yield* _schedules.orderBy('time').snapshots().map((snapshot) => snapshot
          .docs
          .map((doc) => BusSchedule.fromJson(doc.data(), id: doc.id))
          .toList());
    })();
  }

  Stream<List<Bus>> watchBuses() {
    return (() async* {
      final user = FirebaseAuth.instance.currentUser;
      try {
        await user?.getIdToken(true);
      } catch (_) {}
      yield* _buses.snapshots().map((snapshot) => snapshot.docs
          .map((doc) => Bus.fromJson(doc.data(), id: doc.id))
          .toList());
    })();
  }

  Stream<List<BusRoute>> watchRoutes() {
    return (() async* {
      final user = FirebaseAuth.instance.currentUser;
      try {
        await user?.getIdToken(true);
      } catch (_) {}
      yield* _routes.snapshots().map((snapshot) => snapshot.docs
          .map((doc) => BusRoute.fromJson(doc.data(), id: doc.id))
          .toList());
    })();
  }

  Stream<List<BusLocation>> watchBusLocations() {
    return _busLocations.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => BusLocation.fromJson(doc.data(), busId: doc.id))
        .toList());
  }

  Future<Student?> fetchStudent(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    return Student.fromJson(doc.data()!, uid: doc.id);
  }

  Future<void> upsertStudent(Student student) {
    return _users
        .doc(student.uid)
        .set(student.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteUser(String uid) {
    return _users.doc(uid).delete();
  }

  Future<Student> ensureStudentProfile(
    User user, {
    String? name,
    String? kuetId,
    String? department,
    String? batch,
    String? bloodGroup,
    String? hometown,
    String? phoneNumber,
    String? photoUrl,
    String? photoPath,
  }) async {
    final existing = await fetchStudent(user.uid);
    if (existing != null) {
      return existing;
    }

    final localPart = (user.email ?? '').split('@').first;
    final derivedKuetId = _extractKuetId(localPart);
    final student = Student(
      uid: user.uid,
      name: (name ?? user.displayName ?? 'KUET Student').trim(),
      email: user.email ?? '',
      kuetId: (kuetId ?? derivedKuetId).trim(),
      department: (department ?? 'Not provided').trim(),
      batch: (batch ?? _deriveBatch(kuetId ?? derivedKuetId)).trim(),
      role: 'student',
      bloodGroup: _nullIfBlank(bloodGroup),
      hometown: _nullIfBlank(hometown),
      phoneNumber: _nullIfBlank(phoneNumber),
      photoUrl: photoUrl ?? user.photoURL,
      photoPath: photoPath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await upsertStudent(student);
    return student;
  }

  String _extractKuetId(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    return match?.group(0) ?? '';
  }

  String _deriveBatch(String kuetId) {
    if (kuetId.length < 2) {
      return 'Not provided';
    }
    final prefix = kuetId.substring(0, 2);
    return '20$prefix';
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Future<void> updateBusLocation(BusLocation location) {
    return _busLocations
        .doc(location.busId)
        .set(location.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteBusLocation(String busId) {
    return _busLocations.doc(busId).delete();
  }

  Future<DocumentReference<Map<String, dynamic>>> addNotice(Notice notice) {
    return _notices.add(notice.toJson());
  }

  Future<void> upsertNotice(Notice notice) {
    if (notice.id == null || notice.id!.isEmpty) {
      return _notices.add(notice.toJson()).then((_) => null);
    }
    return _notices
        .doc(notice.id)
        .set(notice.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteNotice(String docId) {
    return _notices.doc(docId).delete();
  }

  Future<void> upsertBus(Bus bus) {
    final numberKey = _normalizeKey(bus.busNumber);
    if (numberKey.isEmpty) {
      return Future.error(Exception('Bus number is required'));
    }

    final busRef = (bus.id == null || bus.id!.isEmpty)
        ? _buses.doc()
        : _buses.doc(bus.id);

    final busData = bus.toJson()
      ..['busNumberKey'] = numberKey
      ..['updatedAt'] = bus.updatedAt ?? DateTime.now();
    if (busData['createdAt'] == null) {
      busData['createdAt'] = bus.createdAt ?? DateTime.now();
    }

    final indexRef = _uniqueBusNumbers.doc(numberKey);

    return _db.runTransaction((txn) async {
      final busSnap = await txn.get(busRef);
      final oldKey = busSnap.data()?['busNumberKey']?.toString().trim();

      final indexSnap = await txn.get(indexRef);
      if (indexSnap.exists) {
        final claimed = indexSnap.data()?['busId']?.toString();
        if (claimed != busRef.id) {
          throw Exception('Bus number already exists');
        }
      } else {
        txn.set(indexRef, {
          'busId': busRef.id,
          'busNumber': bus.busNumber.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (oldKey != null &&
          oldKey.isNotEmpty &&
          oldKey != numberKey) {
        final oldIndexRef = _uniqueBusNumbers.doc(oldKey);
        final oldIndexSnap = await txn.get(oldIndexRef);
        final claimed = oldIndexSnap.data()?['busId']?.toString();
        if (oldIndexSnap.exists && claimed == busRef.id) {
          txn.delete(oldIndexRef);
        }
      }

      txn.set(busRef, busData, SetOptions(merge: true));
    });
  }

  Future<void> deleteBus(String docId) {
    final busRef = _buses.doc(docId);
    return _db.runTransaction((txn) async {
      final snap = await txn.get(busRef);
      final key = snap.data()?['busNumberKey']?.toString().trim();
      if (key != null && key.isNotEmpty) {
        final indexRef = _uniqueBusNumbers.doc(key);
        final indexSnap = await txn.get(indexRef);
        final claimed = indexSnap.data()?['busId']?.toString();
        if (indexSnap.exists && claimed == docId) {
          txn.delete(indexRef);
        }
      }
      txn.delete(busRef);
    });
  }

  Future<void> upsertRoute(BusRoute route) {
    final nameKey = _normalizeKey(route.routeName);
    if (nameKey.isEmpty) {
      return Future.error(Exception('Route name is required'));
    }

    final routeRef = (route.id == null || route.id!.isEmpty)
        ? _routes.doc()
        : _routes.doc(route.id);

    final routeData = route.toJson()
      ..['routeNameKey'] = nameKey
      ..['updatedAt'] = route.updatedAt ?? DateTime.now();
    if (routeData['createdAt'] == null) {
      routeData['createdAt'] = route.createdAt ?? DateTime.now();
    }

    final indexRef = _uniqueRouteNames.doc(nameKey);

    return _db.runTransaction((txn) async {
      final routeSnap = await txn.get(routeRef);
      final oldKey = routeSnap.data()?['routeNameKey']?.toString().trim();

      final indexSnap = await txn.get(indexRef);
      if (indexSnap.exists) {
        final claimed = indexSnap.data()?['routeId']?.toString();
        if (claimed != routeRef.id) {
          throw Exception('Route name already exists');
        }
      } else {
        txn.set(indexRef, {
          'routeId': routeRef.id,
          'routeName': route.routeName.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (oldKey != null &&
          oldKey.isNotEmpty &&
          oldKey != nameKey) {
        final oldIndexRef = _uniqueRouteNames.doc(oldKey);
        final oldIndexSnap = await txn.get(oldIndexRef);
        final claimed = oldIndexSnap.data()?['routeId']?.toString();
        if (oldIndexSnap.exists && claimed == routeRef.id) {
          txn.delete(oldIndexRef);
        }
      }

      txn.set(routeRef, routeData, SetOptions(merge: true));
    });
  }

  Future<void> deleteRoute(String docId) {
    final routeRef = _routes.doc(docId);
    return _db.runTransaction((txn) async {
      final snap = await txn.get(routeRef);
      final key = snap.data()?['routeNameKey']?.toString().trim();
      if (key != null && key.isNotEmpty) {
        final indexRef = _uniqueRouteNames.doc(key);
        final indexSnap = await txn.get(indexRef);
        final claimed = indexSnap.data()?['routeId']?.toString();
        if (indexSnap.exists && claimed == docId) {
          txn.delete(indexRef);
        }
      }
      txn.delete(routeRef);
    });
  }

  Future<void> upsertSchedule(BusSchedule schedule) {
    if (schedule.id == null || schedule.id!.isEmpty) {
      return _schedules.add(schedule.toJson()).then((_) => null);
    }
    return _schedules
        .doc(schedule.id)
        .set(schedule.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteSchedule(String docId) {
    return _schedules.doc(docId).delete();
  }
}
