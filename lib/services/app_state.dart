import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../firebase_options.dart';
import '../screens/models/student.dart';
import '../screens/models/income_bracket.dart';
import '../screens/models/scholarship.dart';
import '../screens/models/application_status.dart';
import '../screens/models/verification_status.dart';
import '../screens/models/scholarship_report.dart';
import 'database_helper.dart';
import 'notification_service.dart';

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  AppState() {
    WidgetsBinding.instance.addObserver(this);
  }

  bool loggedIn = false;
  bool adminMode = false;
  int? currentUserId;
  String? currentUserEmail;
  Student student = Student();
  final Set<String> saved = {};
  final Map<String, Set<String>> completedDocs = {};
  final Map<String, ApplicationStatus> applicationStatuses = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _applicationStatusSubscription;
  String? _applicationStatusFirebaseUid;
  String? applicationStatusSyncError;
  int _scholarshipUpdatesFound = 0;
  List<Scholarship> scholarships = sampleScholarships;
  final DatabaseHelper _db = DatabaseHelper.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final NotificationService _notifications = NotificationService.instance;
  bool _googleInitialized = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && loggedIn && !adminMode) {
      unawaited(_refreshOnlineDataOnResume());
    }
  }

  Future<void> _refreshOnlineDataOnResume() async {
    await _syncScholarshipsFromCloud();
    await syncPendingScholarshipReports();
    if (_scholarshipUpdatesFound > 0) await _enableDeadlineReminders();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> load() async {
    loggedIn = false;
    adminMode = false;

    final storedScholarships = await _db.getScholarships();
    final storedIds = storedScholarships.map((s) => s.id).toSet();
    for (final scholarship in sampleScholarships) {
      if (!storedIds.contains(scholarship.id)) {
        await _db.saveScholarship(scholarship);
      }
    }
    scholarships = await _db.getScholarships();
    await _syncScholarshipsFromCloud();
    saved.clear();
    completedDocs.clear();
    applicationStatuses.clear();
    await _restoreAuthenticatedSession();
    notifyListeners();
  }

  bool _scholarshipChanged(Scholarship cached, Scholarship latest) =>
      cached.name != latest.name ||
      cached.provider != latest.provider ||
      cached.description != latest.description ||
      cached.minGwa != latest.minGwa ||
      cached.maxIncome != latest.maxIncome ||
      cached.deadline != latest.deadline ||
      cached.applicationUrl != latest.applicationUrl ||
      cached.benefits != latest.benefits ||
      cached.applicationPeriod != latest.applicationPeriod ||
      cached.sourceUrl != latest.sourceUrl ||
      cached.verificationStatus != latest.verificationStatus ||
      cached.lastVerifiedAt != latest.lastVerifiedAt ||
      cached.courses.join('\u0000') != latest.courses.join('\u0000') ||
      cached.yearLevels.join(',') != latest.yearLevels.join(',') ||
      cached.requirements.join('\u0000') !=
          latest.requirements.join('\u0000') ||
      cached.descriptiveRequirements.join('\u0000') !=
          latest.descriptiveRequirements.join('\u0000');

  Future<void> _restoreAuthenticatedSession() async {
    if (Firebase.apps.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null ||
        email == null ||
        (!user.emailVerified &&
            !user.providerData
                .any((provider) => provider.providerId == 'google.com'))) {
      return;
    }

    try {
      final userId = await _db.getLocalFirebaseUserId(email);
      if (userId == null) {
        final claims = (await user.getIdTokenResult()).claims;
        if (claims?['admin'] != true) return;
        currentUserId = null;
        currentUserEmail = email;
        loggedIn = true;
        adminMode = true;
        return;
      }
      currentUserId = userId;
      currentUserEmail = email;
      loggedIn = true;
      adminMode = false;
      student = await _db.getStudentProfile(userId: userId) ?? Student();
      saved
        ..clear()
        ..addAll(await _db.getSavedScholarships(userId: userId));
      completedDocs
        ..clear()
        ..addAll(await _db.getCompletedDocuments(userId: userId));
      applicationStatuses
        ..clear()
        ..addAll(await _db.getApplicationStatuses(userId: userId));
      _startApplicationStatusSync(user.uid);
      unawaited(syncPendingScholarshipReports());
      unawaited(_enableDeadlineReminders());
    } catch (error) {
      debugPrint('Could not restore the cached account session: $error');
    }
  }

  Future<void> _syncScholarshipsFromCloud() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      final snapshot = await FirebaseFirestore.instance
          .collection('scholarships')
          .get()
          .timeout(const Duration(seconds: 4));
      if (snapshot.docs.isEmpty) return;

      final cloudScholarships = snapshot.docs
          .map((document) => _scholarshipFromCloud(document.data()))
          .whereType<Scholarship>()
          .toList();
      if (cloudScholarships.isEmpty) return;

      final cachedById = {for (final item in scholarships) item.id: item};
      _scholarshipUpdatesFound = cloudScholarships.where((latest) {
        final cached = cachedById[latest.id];
        return cached != null && _scholarshipChanged(cached, latest);
      }).length;
      for (final scholarship in cloudScholarships) {
        await _db.saveScholarship(scholarship);
      }
      final merged = {for (final item in scholarships) item.id: item};
      for (final scholarship in cloudScholarships) {
        merged[scholarship.id] = scholarship;
      }
      scholarships = merged.values.toList();
      if (_scholarshipUpdatesFound > 0) notifyListeners();
    } catch (error) {
      debugPrint(
          'Cloud scholarship refresh unavailable; using cached data: $error');
    }
  }

  Scholarship? _scholarshipFromCloud(Map<String, dynamic> data) {
    final id = data['id'] as String?;
    final deadlineValue = data['deadline'];
    final deadline = deadlineValue is Timestamp
        ? deadlineValue.toDate()
        : DateTime.tryParse(deadlineValue?.toString() ?? '');
    if (id == null || deadline == null) return null;

    final verifiedValue = data['lastVerifiedAt'];
    final verifiedAt = verifiedValue is Timestamp
        ? verifiedValue.toDate()
        : DateTime.tryParse(verifiedValue?.toString() ?? '');

    return Scholarship(
      id: id,
      name: data['name'] as String? ?? 'Scholarship',
      provider: data['provider'] as String? ?? 'Scholarship Provider',
      description: data['description'] as String? ?? '',
      minGwa: (data['minGwa'] as num?)?.toDouble() ?? 0,
      courses: List<String>.from(data['courses'] ?? const []),
      yearLevels: List<num>.from(data['yearLevels'] ?? const [])
          .map((level) => level.toInt())
          .toList(),
      maxIncome: (data['maxIncome'] as num?)?.toDouble() ?? 0,
      deadline: deadline,
      requirements: List<String>.from(data['requirements'] ?? const []),
      applicationUrl: data['applicationUrl'] as String? ?? '',
      benefits: data['benefits'] as String? ?? '',
      applicationPeriod: data['applicationPeriod'] as String? ?? '',
      sourceUrl: data['sourceUrl'] as String? ?? '',
      verificationStatus:
          VerificationStatus.fromName(data['verificationStatus'] as String?),
      lastVerifiedAt: verifiedAt,
      descriptiveRequirements:
          List<String>.from(data['descriptiveRequirements'] ?? const []),
    );
  }

  Future<void> save() async {
    if (currentUserId != null && !adminMode) {
      await _db.saveStudentProfile(student, userId: currentUserId!);
    }
    await _db.saveSession(loggedIn: loggedIn, adminMode: adminMode);
  }

  Future<dynamic> login({
    required String email,
    required String password,
    bool createAccount = false,
  }) async {
    try {
      await _stopApplicationStatusSync();
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      final auth = FirebaseAuth.instance;
      final normalizedEmail = email.trim().toLowerCase();
      if (createAccount) {
        if (!isStrongPassword(password)) return 'weak-password';
        final credential = await auth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );
        final user = credential.user;
        if (user == null) return false;
        try {
          await user.sendEmailVerification();
        } finally {
          await auth.signOut();
        }
        return 'verification-sent';
      }

      final credential = await auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = credential.user;
      if (user == null) return false;
      if (!user.emailVerified) {
        try {
          await user.sendEmailVerification();
        } finally {
          await auth.signOut();
        }
        return 'verification-required';
      }

      final claims = (await user.getIdTokenResult()).claims;
      final admin = claims?['admin'] == true;
      final userId = admin
          ? null
          : await _db.getOrCreateFirebaseUser(
              email: normalizedEmail,
              fullName: user.displayName ?? '',
            );
      if (!admin && userId == null) {
        await auth.signOut();
        return 'account-restricted';
      }

      currentUserId = userId;
      currentUserEmail = user.email;
      loggedIn = true;
      adminMode = admin;

      if (!admin) {
        student = await _db.getStudentProfile(userId: userId!) ?? Student();
        saved
          ..clear()
          ..addAll(await _db.getSavedScholarships(userId: userId));
        completedDocs
          ..clear()
          ..addAll(await _db.getCompletedDocuments(userId: userId));
        applicationStatuses
          ..clear()
          ..addAll(await _db.getApplicationStatuses(userId: userId));
        _startApplicationStatusSync(user.uid);
      }

      await save();
      unawaited(syncPendingScholarshipReports());
      unawaited(_enableDeadlineReminders());
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (error) {
      return 'auth:${error.code}';
    } catch (error) {
      debugPrint('Email authentication failed: $error');
      return 'auth:unknown';
    }
  }

  static bool isStrongPassword(String password) =>
      password.length >= 12 &&
      RegExp(r'[a-z]').hasMatch(password) &&
      RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[0-9]').hasMatch(password) &&
      RegExp(r'[^A-Za-z0-9]').hasMatch(password);

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );
      return null;
    } on FirebaseAuthException catch (error) {
      return 'auth:${error.code}';
    }
  }

  Future<bool> submitScholarshipReport({
    required Scholarship scholarship,
    required String note,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = currentUserId;
    if (user == null || !loggedIn || adminMode || userId == null) {
      throw StateError(
          'Sign in as a student to report scholarship information.');
    }
    final cleanedNote = note.trim();
    if (cleanedNote.length < 10 || cleanedNote.length > 1000) {
      throw ArgumentError.value(
        note,
        'note',
        'Report details must contain 10 to 1000 characters.',
      );
    }

    final createdAt = DateTime.now().toUtc();
    final localId = await _db.saveScholarshipReport(ScholarshipReport(
      userId: userId,
      ownerUid: user.uid,
      scholarshipId: scholarship.id,
      note: cleanedNote,
      createdAt: createdAt,
      pendingSync: true,
    ));
    final firestoreId =
        '${user.uid}_report_${createdAt.microsecondsSinceEpoch}_$localId';
    final report = ScholarshipReport(
      id: localId,
      userId: userId,
      ownerUid: user.uid,
      scholarshipId: scholarship.id,
      note: cleanedNote,
      createdAt: createdAt,
      firestoreId: firestoreId,
      pendingSync: true,
    );
    try {
      await _writeScholarshipReport(report).timeout(const Duration(seconds: 3));
      await _db.markScholarshipReportSynced(localId, firestoreId);
      return true;
    } catch (error) {
      debugPrint('Scholarship report queued for sync: $error');
      return false;
    }
  }

  Future<void> syncPendingScholarshipReports() async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = currentUserId;
    if (user == null || userId == null || adminMode) return;
    final reports = await _db.getPendingScholarshipReports(user.uid);
    for (final report in reports) {
      final localId = report.id;
      if (localId == null) continue;
      final firestoreId =
          '${user.uid}_report_${report.createdAt.microsecondsSinceEpoch}_$localId';
      try {
        await _writeScholarshipReport(
          report.copyWith(firestoreId: firestoreId),
        ).timeout(const Duration(seconds: 3));
        await _db.markScholarshipReportSynced(localId, firestoreId);
      } catch (error) {
        debugPrint('Scholarship report $localId remains queued: $error');
      }
    }
  }

  Future<void> _writeScholarshipReport(ScholarshipReport report) async {
    final user = FirebaseAuth.instance.currentUser;
    final firestoreId = report.firestoreId;
    if (user == null || firestoreId == null || user.uid != report.ownerUid) {
      throw StateError('The report does not belong to the current account.');
    }
    await FirebaseFirestore.instance
        .collection('scholarshipReports')
        .doc(firestoreId)
        .set({
      'scholarshipId': report.scholarshipId,
      'reporterUid': user.uid,
      'reason': 'outdatedOrInconsistent',
      'note': report.note,
      'status': report.status.name,
      'createdAt': Timestamp.fromDate(report.createdAt),
    });
  }

  Future<List<ScholarshipReport>> getScholarshipReports() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null ||
        (await user.getIdTokenResult()).claims?['admin'] != true) {
      throw StateError('Administrator access is required to view reports.');
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('scholarshipReports')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get()
        .timeout(const Duration(seconds: 8));
    final reports = snapshot.docs.map((document) {
      final data = document.data();
      final createdAt = data['createdAt'];
      final reviewedAt = data['reviewedAt'];
      return ScholarshipReport(
        userId: 0,
        ownerUid: data['reporterUid'] as String? ?? '',
        scholarshipId: data['scholarshipId'] as String? ?? '',
        note: data['note'] as String? ?? '',
        createdAt: createdAt is Timestamp
            ? createdAt.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0),
        status: ReportStatus.fromName(data['status'] as String?),
        reviewerNote: data['reviewerNote'] as String? ?? '',
        reviewedAt: reviewedAt is Timestamp ? reviewedAt.toDate() : null,
        firestoreId: document.id,
      );
    }).toList();
    reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reports;
  }

  Future<void> updateScholarshipReport(
    ScholarshipReport report,
    ReportStatus status,
    String reviewerNote,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    final firestoreId = report.firestoreId;
    if (user == null ||
        (await user.getIdTokenResult()).claims?['admin'] != true) {
      throw StateError('Administrator access is required to update reports.');
    }
    if (firestoreId == null) {
      throw StateError('This report has not synchronized to Firebase yet.');
    }
    await FirebaseFirestore.instance
        .collection('scholarshipReports')
        .doc(firestoreId)
        .update({
      'status': status.name,
      'reviewerNote': reviewerNote.trim(),
      'reviewerUid': user.uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    })
    .timeout(const Duration(seconds: 8));
    await _db.updateLocalScholarshipReportByFirestoreId(
      firestoreId,
      report.copyWith(
        status: status,
        reviewerNote: reviewerNote.trim(),
        reviewedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<dynamic> loginWithGoogle() async {
    try {
      await _stopApplicationStatusSync();
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      if (!_googleInitialized) {
        await _googleSignIn.initialize();
        _googleInitialized = true;
      }
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) return 'missing-token';

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final result =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = result.user;
      if (firebaseUser == null || firebaseUser.email == null) return false;

      final tokenClaims = (await firebaseUser.getIdTokenResult()).claims;
      final hasAdminClaim = tokenClaims?['admin'] == true;
      final userId = hasAdminClaim
          ? null
          : await _db.getOrCreateFirebaseUser(
              email: firebaseUser.email!,
              fullName: firebaseUser.displayName ?? '',
            );
      if (!hasAdminClaim && userId == null) {
        await FirebaseAuth.instance.signOut();
        await _googleSignIn.signOut();
        return 'admin-account';
      }

      currentUserId = userId;
      currentUserEmail = firebaseUser.email;
      loggedIn = true;
      adminMode = hasAdminClaim;
      if (!adminMode) {
        student = await _db.getStudentProfile(userId: userId!) ?? Student();
        saved
          ..clear()
          ..addAll(await _db.getSavedScholarships(userId: userId));
        completedDocs
          ..clear()
          ..addAll(await _db.getCompletedDocuments(userId: userId));
        applicationStatuses
          ..clear()
          ..addAll(await _db.getApplicationStatuses(userId: userId));
        _startApplicationStatusSync(firebaseUser.uid);
      }
      await save();
      unawaited(syncPendingScholarshipReports());
      unawaited(_enableDeadlineReminders());
      notifyListeners();
      return true;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return 'canceled';
      return false;
    } on FirebaseAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _enableDeadlineReminders() async {
    await _notifications.requestPermission();
    if (_scholarshipUpdatesFound > 0) {
      await _notifications.notifyScholarshipUpdates(_scholarshipUpdatesFound);
      _scholarshipUpdatesFound = 0;
    }
    await _notifications.scheduleDeadlineReminders(
      scholarships
          .where((scholarship) => saved.contains(scholarship.id))
          .toList(),
    );
  }

  void logout() {
    unawaited(_stopApplicationStatusSync());
    unawaited(FirebaseAuth.instance.signOut());
    unawaited(_googleSignIn.signOut());
    loggedIn = false;
    adminMode = false;
    currentUserId = null;
    currentUserEmail = null;
    unawaited(_notifications.cancelAllDeadlineReminders());
    unawaited(save());
    notifyListeners();
  }

  void updateStudent(Student value) {
    if (!loggedIn || adminMode || currentUserId == null) return;
    student = value;
    unawaited(save());
    notifyListeners();
  }

  bool qualifies(Scholarship s) {
    if (s.isArchived) return false;
    final gwaOk = student.gwa > 0 && student.gwa <= s.minGwa;
    final courseOk = s.courses.isEmpty ||
        s.courses.any(
          (c) => student.course.toLowerCase().contains(c.toLowerCase()),
        );
    final yearOk =
        s.yearLevels.isEmpty || s.yearLevels.contains(student.yearLevel);
    final bracket = student.incomeBracket ??
        (student.householdIncome > 0
            ? IncomeBracket.fromMonthlyIncome(student.householdIncome)
            : null);
    final incomeOk = bracket != null && bracket.upperBound <= s.maxIncome;
    return gwaOk && courseOk && yearOk && incomeOk;
  }

  void toggleSaved(String id) {
    if (!loggedIn || adminMode || currentUserId == null) return;
    if (saved.contains(id)) {
      saved.remove(id);
    } else {
      saved.add(id);
    }
    unawaited(_db.toggleSavedScholarship(id, userId: currentUserId!));
    unawaited(_syncDeadlineRemindersForScholarship(id));
    notifyListeners();
  }

  Future<void> _syncDeadlineRemindersForScholarship(String id) async {
    if (!scholarships.any((item) => item.id == id)) return;
    await _notifications.scheduleDeadlineReminders(
      scholarships.where((item) => saved.contains(item.id)).toList(),
    );
  }

  bool isDocDone(String scholarshipId, String doc) =>
      completedDocs[scholarshipId]?.contains(doc) ?? false;

  void toggleDoc(String scholarshipId, String doc) {
    if (!loggedIn || adminMode || currentUserId == null) return;
    completedDocs.putIfAbsent(scholarshipId, () => {});
    final set = completedDocs[scholarshipId]!;
    if (set.contains(doc)) {
      set.remove(doc);
    } else {
      set.add(doc);
    }
    unawaited(
        _db.toggleDocumentDone(scholarshipId, doc, userId: currentUserId!));
    notifyListeners();
  }

  ApplicationStatus applicationStatus(String scholarshipId) =>
      applicationStatuses[scholarshipId] ?? ApplicationStatus.notStarted;

  bool get applicationStatusSyncEnabled =>
      _applicationStatusFirebaseUid != null;

  Future<void> updateApplicationStatus(
      String scholarshipId, ApplicationStatus status) async {
    if (!loggedIn || adminMode || currentUserId == null) return;
    applicationStatuses[scholarshipId] = status;
    applicationStatusSyncError = null;
    notifyListeners();
    final userId = currentUserId!;
    await _db.saveApplicationStatus(
        userId: userId, scholarshipId: scholarshipId, status: status);
    final uid = _applicationStatusFirebaseUid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('applicationStatuses')
          .doc(scholarshipId)
          .set({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      applicationStatusSyncError =
          'Status is saved on this device, but could not sync to Firebase: $error';
      notifyListeners();
      rethrow;
    }
  }

  void _startApplicationStatusSync(String uid) {
    unawaited(_stopApplicationStatusSync());
    _applicationStatusFirebaseUid = uid;
    applicationStatusSyncError = null;
    final collection = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('applicationStatuses');
    _applicationStatusSubscription = collection.snapshots().listen((snapshot) {
      unawaited(_applyApplicationStatusSnapshot(uid, collection, snapshot));
    }, onError: (Object error) {
      _setApplicationStatusSyncError(uid, error);
    });
    notifyListeners();
  }

  Future<void> _applyApplicationStatusSnapshot(
    String uid,
    CollectionReference<Map<String, dynamic>> collection,
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (_applicationStatusFirebaseUid != uid || currentUserId == null) return;
    try {
      final localUserId = currentUserId!;
      final localStatuses =
          await _db.getApplicationStatuses(userId: localUserId);
      var changed = false;
      final remoteIds = <String>{};
      for (final document in snapshot.docs) {
        final rawStatus = document.data()['status'] as String?;
        if (rawStatus == null ||
            !ApplicationStatus.values.any((item) => item.name == rawStatus)) {
          continue;
        }
        final status = ApplicationStatus.fromName(rawStatus);
        remoteIds.add(document.id);
        if (applicationStatuses[document.id] != status) {
          applicationStatuses[document.id] = status;
          changed = true;
        }
        if (localStatuses[document.id] != status) {
          await _db.saveApplicationStatus(
            userId: localUserId,
            scholarshipId: document.id,
            status: status,
          );
        }
      }

      if (!snapshot.metadata.isFromCache &&
          _applicationStatusFirebaseUid == uid) {
        for (final entry in localStatuses.entries) {
          if (remoteIds.contains(entry.key)) continue;
          await collection.doc(entry.key).set({
            'status': entry.value.name,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      final hadError = applicationStatusSyncError != null;
      applicationStatusSyncError = null;
      if ((changed || hadError) && _applicationStatusFirebaseUid == uid) {
        notifyListeners();
      }
    } catch (error) {
      _setApplicationStatusSyncError(uid, error);
    }
  }

  void _setApplicationStatusSyncError(String uid, Object error) {
    if (_applicationStatusFirebaseUid != uid) return;
    applicationStatusSyncError =
        'Live application-status sync is unavailable: $error';
    notifyListeners();
  }

  Future<void> _stopApplicationStatusSync() async {
    await _applicationStatusSubscription?.cancel();
    _applicationStatusSubscription = null;
    _applicationStatusFirebaseUid = null;
    applicationStatusSyncError = null;
  }

  void completeAllDocs(String scholarshipId, List<String> documents) {
    if (!loggedIn || adminMode || currentUserId == null) return;
    final set = completedDocs.putIfAbsent(scholarshipId, () => {});
    for (final document in documents) {
      if (set.add(document)) {
        unawaited(_db.toggleDocumentDone(scholarshipId, document,
            userId: currentUserId!));
      }
    }
    notifyListeners();
  }

  void addScholarship(Scholarship s) {
    if (!loggedIn || !adminMode) return;
    scholarships = [...scholarships, s];
    unawaited(_db.saveScholarship(s));
    notifyListeners();
  }

  Future<bool> syncScholarshipToCloud(Scholarship scholarship) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final claims = (await user.getIdTokenResult()).claims;
    if (claims?['admin'] != true) return false;

    await FirebaseFirestore.instance
        .collection('scholarships')
        .doc(scholarship.id)
        .set({
      'id': scholarship.id,
      'name': scholarship.name,
      'provider': scholarship.provider,
      'description': scholarship.description,
      'minGwa': scholarship.minGwa,
      'courses': scholarship.courses,
      'yearLevels': scholarship.yearLevels,
      'maxIncome': scholarship.maxIncome,
      'deadline': scholarship.deadline.toIso8601String(),
      'requirements': scholarship.requirements,
      'applicationUrl': scholarship.applicationUrl,
      'benefits': scholarship.benefits,
      'applicationPeriod': scholarship.applicationPeriod,
      'sourceUrl': scholarship.sourceUrl,
      'verificationStatus': scholarship.verificationStatus.name,
      'lastVerifiedAt': scholarship.lastVerifiedAt?.toIso8601String(),
      'descriptiveRequirements': scholarship.descriptiveRequirements,
    });
    return true;
  }

  Future<bool> deleteScholarshipFromCloud(String scholarshipId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final claims = (await user.getIdTokenResult()).claims;
    if (claims?['admin'] != true) return false;
    await FirebaseFirestore.instance
        .collection('scholarships')
        .doc(scholarshipId)
        .delete();
    return true;
  }

  void updateScholarship(Scholarship scholarship) {
    if (!loggedIn || !adminMode) return;
    scholarships = scholarships
        .map((item) => item.id == scholarship.id ? scholarship : item)
        .toList();
    unawaited(_db.saveScholarship(scholarship));
    if (saved.contains(scholarship.id)) {
      unawaited(_notifications.scheduleDeadlineReminders(
        scholarships.where((item) => saved.contains(item.id)).toList(),
      ));
    }
    notifyListeners();
  }

  void deleteScholarship(String id) {
    if (!loggedIn || !adminMode) return;
    scholarships = scholarships.where((s) => s.id != id).toList();
    saved.remove(id);
    unawaited(_db.deleteScholarship(id));
    notifyListeners();
  }
}

final sampleScholarships = <Scholarship>[
  Scholarship(
    id: 'icct',
    name: 'ICCT Academic Scholarship',
    provider: 'ICCT Colleges',
    description:
        'Financial assistance opportunity for qualified college students based on academic performance and profile information.',
    minGwa: 1.75,
    courses: [],
    yearLevels: [1, 2, 3, 4],
    maxIncome: 50000,
    deadline: DateTime(2026, 9, 30),
    requirements: [
      'Updated grades / GWA',
      'Certificate of enrollment',
      'Valid school ID',
      'Proof of household income'
    ],
    applicationUrl: 'https://www.icct.edu.ph/',
  ),
  Scholarship(
    id: 'city',
    name: 'Local Government Student Grant',
    provider: 'Local Government Unit',
    description:
        'A sample local government scholarship listing for demonstration and testing of the IskolarHub matching feature.',
    minGwa: 2.00,
    courses: [],
    yearLevels: [1, 2, 3, 4],
    maxIncome: 30000,
    deadline: DateTime(2026, 10, 15),
    requirements: [
      'Grades',
      'Certificate of enrollment',
      'Barangay certificate',
      'Income document'
    ],
    applicationUrl: 'https://www.gov.ph/',
  ),
  Scholarship(
    id: 'tech',
    name: 'Technology Student Assistance',
    provider: 'Partner Foundation',
    description:
        'Sample scholarship intended for technology-related students with qualifying academic and household-income profiles.',
    minGwa: 2.25,
    courses: ['computer', 'information technology', 'engineering'],
    yearLevels: [2, 3, 4],
    maxIncome: 40000,
    deadline: DateTime(2026, 11, 20),
    requirements: [
      'Latest grades',
      'School ID',
      'Enrollment certificate',
      'Personal statement'
    ],
    applicationUrl: 'https://www.gov.ph/',
  ),
  Scholarship(
    id: 'ched-tes',
    name: 'CHED Tertiary Education Subsidy',
    provider: 'Commission on Higher Education',
    description:
        'Financial assistance for eligible Filipino college students enrolled in recognized higher education institutions.',
    minGwa: 2.50,
    courses: [],
    yearLevels: [1, 2, 3, 4],
    maxIncome: 60000,
    deadline: DateTime(2026, 12, 5),
    requirements: [
      'Certificate of enrollment',
      'Latest grades',
      'Valid government ID',
      'Proof of household income'
    ],
    applicationUrl: 'https://ched.gov.ph/',
  ),
  Scholarship(
    id: 'dost-sei',
    name: 'DOST-SEI Undergraduate Scholarship',
    provider: 'Department of Science and Technology',
    description:
        'A merit-based scholarship for students pursuing priority science, technology, engineering, and mathematics programs.',
    minGwa: 1.75,
    courses: [
      'science',
      'technology',
      'engineering',
      'mathematics',
      'computer'
    ],
    yearLevels: [1],
    maxIncome: 70000,
    deadline: DateTime(2027, 1, 15),
    requirements: [
      'School records',
      'Birth certificate',
      'Income documents',
      'Certificate of admission'
    ],
    applicationUrl: 'https://science-scholarships.ph/',
  ),
  Scholarship(
    id: 'sm-foundation',
    name: 'SM Foundation College Scholarship',
    provider: 'SM Foundation',
    description:
        'Support for hardworking students with strong academic potential and demonstrated financial need.',
    minGwa: 2.00,
    courses: [],
    yearLevels: [1, 2, 3, 4],
    maxIncome: 50000,
    deadline: DateTime(2027, 2, 10),
    requirements: [
      'Grades',
      'Certificate of enrollment',
      'Family income documents',
      'Personal essay'
    ],
    applicationUrl: 'https://www.sm-foundation.org/',
  ),
  Scholarship(
    id: 'ayala-stem',
    name: 'Ayala Foundation STEM Grant',
    provider: 'Ayala Foundation',
    description:
        'A focused grant for students building a future in science, technology, engineering, or mathematics.',
    minGwa: 1.90,
    courses: ['science', 'technology', 'engineering', 'mathematics'],
    yearLevels: [2, 3, 4],
    maxIncome: 45000,
    deadline: DateTime(2027, 3, 1),
    requirements: [
      'Latest grades',
      'School ID',
      'Recommendation letter',
      'Statement of purpose'
    ],
    applicationUrl: 'https://www.ayalafoundation.org/',
  ),
  Scholarship(
    id: 'academic-excellence',
    name: 'Academic Excellence Student Grant',
    provider: 'IskolarHub Community Partners',
    description:
        'A community-supported grant for students who show consistent academic performance and community involvement.',
    minGwa: 1.50,
    courses: [],
    yearLevels: [1, 2, 3, 4],
    maxIncome: 35000,
    deadline: DateTime(2027, 3, 20),
    requirements: [
      'Latest grades',
      'Certificate of enrollment',
      'Community reference',
      'Proof of income'
    ],
    applicationUrl: 'https://www.gov.ph/',
  ),
];
