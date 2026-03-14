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
    if (bus.id == null || bus.id!.isEmpty) {
      return _buses.add(bus.toJson()).then((_) => null);
    }
    return _buses.doc(bus.id).set(bus.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteBus(String docId) {
    return _buses.doc(docId).delete();
  }

  Future<void> upsertRoute(BusRoute route) {
    if (route.id == null || route.id!.isEmpty) {
      return _routes.add(route.toJson()).then((_) => null);
    }
    return _routes.doc(route.id).set(route.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteRoute(String docId) {
    return _routes.doc(docId).delete();
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
