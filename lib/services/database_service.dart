import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId;

  DatabaseService({this.userId});

  Future<int> getTotalUsersCount() async {
    QuerySnapshot snapshot = await _firestore.collection('users').get();
    return snapshot.docs.length;
  }

  Future<int> getTotalAdminsCount() async {
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('isAdmin', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final lowerEmail = email.toLowerCase().trim();
    final originalEmail = email.trim();

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: lowerEmail)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty && lowerEmail != originalEmail) {
      snapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: originalEmail)
          .limit(1)
          .get();
    }

    if (snapshot.docs.isEmpty) return null;
    return {
      'id': snapshot.docs.first.id,
      ...snapshot.docs.first.data() as Map<String, dynamic>,
    };
  }

  Future<DocumentReference> addMedicine(Map<String, dynamic> medicine) async {
    final name = medicine['name'].toString().trim().toLowerCase();
    final type = medicine['type'];
    final dose = medicine['dose'].toString().trim().toLowerCase();

    final snapshot = await _firestore
        .collection('medicines')
        .where('userId', isEqualTo: userId)
        .get();

    final isDuplicate = snapshot.docs.any((doc) {
      final d = doc.data();
      final eName = (d['name']?.toString() ?? '').trim().toLowerCase();
      final eType = d['type'];
      final eDose = (d['dose']?.toString() ?? '').trim().toLowerCase();

      return eName == name && eType == type && eDose == dose;
    });

    if (isDuplicate) {
      throw Exception('This medicine is already in your list');
    }

    medicine['userId'] = userId;
    medicine['createdAt'] = FieldValue.serverTimestamp();
    return await _firestore.collection('medicines').add(medicine);
  }

  Stream<QuerySnapshot> getMedicines() {
    return _firestore
        .collection('medicines')
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<void> updateMedicine(
    String medicineId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('medicines').doc(medicineId).update(data);
  }

  Future<void> deleteMedicine(String medicineId) async {
    await _firestore.collection('medicines').doc(medicineId).delete();
  }

  Future<void> sendLinkRequest({
    required String patientEmail,
    required String monitorName,
    required String monitorEmail,
  }) async {
    Map<String, dynamic>? patient = await getUserByEmail(patientEmail);
    if (patient == null) {
      throw Exception('User not found with this email');
    }

    if (patient['id'] == userId) {
      throw Exception('You cannot send a request to yourself');
    }

    QuerySnapshot existingLinks = await _firestore
        .collection('link_requests')
        .where('monitorId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .get();

    if (existingLinks.docs.length >= 5) {
      throw Exception('You can only link up to 5 patients');
    }

    QuerySnapshot existing = await _firestore
        .collection('link_requests')
        .where('monitorId', isEqualTo: userId)
        .where('patientId', isEqualTo: patient['id'])
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Request already sent to this patient');
    }

    await _firestore.collection('link_requests').add({
      'monitorId': userId,
      'monitorEmail': monitorEmail.toLowerCase(),
      'monitorName': monitorName,
      'patientId': patient['id'],
      'patientEmail': patientEmail.toLowerCase(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getPendingRequests() {
    return _firestore
        .collection('link_requests')
        .where('patientId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Stream<QuerySnapshot> getMyCaregivers() {
    return _firestore
        .collection('link_requests')
        .where('patientId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots();
  }

  Stream<QuerySnapshot> getLinkedPatients() {
    return _firestore
        .collection('link_requests')
        .where('monitorId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots();
  }

  Future<void> acceptLinkRequest(String requestId) async {
    await _firestore.collection('link_requests').doc(requestId).update({
      'status': 'accepted',
    });
  }

  Future<void> rejectLinkRequest(String requestId) async {
    await _firestore.collection('link_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  Future<void> trackDose(String medicineId, String status, String time) async {
    final date = DateTime.now().toIso8601String().split('T')[0];

    final docId =
        "${userId}_${medicineId}_${date}_${time.replaceAll(' ', '_').replaceAll(':', '')}";

    await _firestore.collection('dose_tracking').doc(docId).set({
      'userId': userId,
      'medicineId': medicineId,
      'status': status,
      'date': date,
      'time': time,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getTodayTrackedDoses() {
    final date = DateTime.now().toIso8601String().split('T')[0];
    return _firestore
        .collection('dose_tracking')
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: date)
        .snapshots();
  }

  Future<String> getAppContent(String key) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('app_content')
          .doc(key)
          .get();
      if (!doc.exists) return '';
      return doc.get('content') as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<void> saveAppContent(String key, String content) async {
    await _firestore.collection('app_content').doc(key).set({
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getPatientMedicines(String patientId) {
    return _firestore
        .collection('medicines')
        .where('userId', isEqualTo: patientId)
        .snapshots();
  }
}
