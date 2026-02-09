import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? userId;

  DatabaseService({this.userId});

  // ============== USER OPERATIONS ==============

  // Get total users count
  Future<int> getTotalUsersCount() async {
    QuerySnapshot snapshot = await _firestore.collection('users').get();
    return snapshot.docs.length;
  }

  // Get total admins count
  Future<int> getTotalAdminsCount() async {
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('isAdmin', isEqualTo: true)
        .get();
    return snapshot.docs.length;
  }

  // Get user by email (more robust lookup)
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final lowerEmail = email.toLowerCase().trim();
    final originalEmail = email.trim();

    // Try lowercase first (standard)
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: lowerEmail)
        .limit(1)
        .get();

    // If not found, try original casing (for older records or mismatches)
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

  // ============== MEDICINE OPERATIONS ==============

  // Add medicine with duplicate check
  Future<DocumentReference> addMedicine(Map<String, dynamic> medicine) async {
    final name = medicine['name'].toString().trim().toLowerCase();
    final type = medicine['type'];
    final dose = medicine['dose'].toString().trim().toLowerCase();

    // Get all user medicines to check for duplicates (case-insensitive)
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

  // Get user's medicines
  Stream<QuerySnapshot> getMedicines() {
    return _firestore
        .collection('medicines')
        .where('userId', isEqualTo: userId)
        // .orderBy('createdAt', descending: true) // Removed to avoid index requirement
        .snapshots();
  }

  // Update medicine
  Future<void> updateMedicine(
    String medicineId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('medicines').doc(medicineId).update(data);
  }

  // Delete medicine
  Future<void> deleteMedicine(String medicineId) async {
    await _firestore.collection('medicines').doc(medicineId).delete();
  }

  // ============== LINK REQUEST OPERATIONS ==============

  // Send link request (monitor to patient)
  Future<void> sendLinkRequest({
    required String patientEmail,
    required String monitorName,
    required String monitorEmail,
  }) async {
    // Find patient by email
    Map<String, dynamic>? patient = await getUserByEmail(patientEmail);
    if (patient == null) {
      throw Exception('User not found with this email');
    }

    // Prevent sending request to yourself
    if (patient['id'] == userId) {
      throw Exception('You cannot send a request to yourself');
    }

    // Check if monitor already has 5 patients
    QuerySnapshot existingLinks = await _firestore
        .collection('link_requests')
        .where('monitorId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .get();

    if (existingLinks.docs.length >= 5) {
      throw Exception('You can only link up to 5 patients');
    }

    // Check if request already exists
    QuerySnapshot existing = await _firestore
        .collection('link_requests')
        .where('monitorId', isEqualTo: userId)
        .where('patientId', isEqualTo: patient['id'])
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('Request already sent to this patient');
    }

    // Create link request
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

  // Get pending requests for patient
  Stream<QuerySnapshot> getPendingRequests() {
    return _firestore
        .collection('link_requests')
        .where('patientId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  // Get caregivers (accepted monitors) for patient
  Stream<QuerySnapshot> getMyCaregivers() {
    return _firestore
        .collection('link_requests')
        .where('patientId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots();
  }

  // Get linked patients for monitor
  Stream<QuerySnapshot> getLinkedPatients() {
    return _firestore
        .collection('link_requests')
        .where('monitorId', isEqualTo: userId)
        .where('status', isEqualTo: 'accepted')
        .snapshots();
  }

  // Accept link request
  Future<void> acceptLinkRequest(String requestId) async {
    await _firestore.collection('link_requests').doc(requestId).update({
      'status': 'accepted',
    });
  }

  // Reject link request
  Future<void> rejectLinkRequest(String requestId) async {
    await _firestore.collection('link_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  // ============== DOSE TRACKING OPERATIONS ==============

  // Track a specific dose (taken or missed) at a specific time
  Future<void> trackDose(String medicineId, String status, String time) async {
    final date = DateTime.now().toIso8601String().split('T')[0];
    // Include time in docId to allow tracking multiple doses per day correctly
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

  // Get today's tracked doses
  Stream<QuerySnapshot> getTodayTrackedDoses() {
    final date = DateTime.now().toIso8601String().split('T')[0];
    return _firestore
        .collection('dose_tracking')
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: date)
        .snapshots();
  }

  // ============== APP CONTENT OPERATIONS ==============

  // Get app content (About Us, Help & FAQ)
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

  // Save app content (Admin only)
  Future<void> saveAppContent(String key, String content) async {
    await _firestore.collection('app_content').doc(key).set({
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============== HELPER METHODS ==============

  // Get patient medicines (for monitor)
  Stream<QuerySnapshot> getPatientMedicines(String patientId) {
    return _firestore
        .collection('medicines')
        .where('userId', isEqualTo: patientId)
        .snapshots();
  }
}
