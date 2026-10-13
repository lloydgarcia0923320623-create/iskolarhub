import 'package:flutter_test/flutter_test.dart';
import 'package:iskolarhub/screens/models/student.dart';
import 'package:iskolarhub/screens/models/income_bracket.dart';
import 'package:iskolarhub/screens/models/scholarship.dart';
import 'package:iskolarhub/screens/models/scholarship_report.dart';
import 'package:iskolarhub/screens/models/application_status.dart';
import 'package:iskolarhub/screens/models/verification_status.dart';
import 'package:iskolarhub/services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  databaseFactory = databaseFactoryFfi;

  test('database helper can save and read a student profile', () async {
    final helper = DatabaseHelper.instance;
    await helper.clearDatabaseForTest();

    final student = Student(
      name: 'Lloyd Andrei Garcia',
      course: 'Computer Engineering',
      yearLevel: 4,
      gwa: 1.75,
      householdIncome: 35000,
    );

    await helper.saveStudentProfile(student, userId: 1);
    final saved = await helper.getStudentProfile(userId: 1);

    expect(saved, isNotNull);
    expect(saved!.name, 'Lloyd Andrei Garcia');
    expect(saved.course, 'Computer Engineering');
    expect(saved.yearLevel, 4);
    expect(saved.gwa, 1.75);
    expect(saved.householdIncome, 35000);
  });

  test('database helper persists the selected household income bracket',
      () async {
    final helper = DatabaseHelper.instance;
    await helper.clearDatabaseForTest();
    final userId = await helper.getOrCreateFirebaseUser(
      email: 'bracket@example.com',
      fullName: 'Bracket Student',
    );
    await helper.saveStudentProfile(
      Student(
        name: 'Bracket Student',
        householdIncome: 20000,
        incomeBracket: IncomeBracket.upToTwentyThousand,
      ),
      userId: userId!,
    );

    final saved = await helper.getStudentProfile(userId: userId);
    expect(saved?.incomeBracket, IncomeBracket.upToTwentyThousand);
    expect(saved?.householdIncome, 20000);
  });

  test('scholarship reports remain queued locally until marked synced',
      () async {
    final helper = DatabaseHelper.instance;
    await helper.clearDatabaseForTest();
    final userId = await helper.getOrCreateFirebaseUser(
      email: 'reporter@example.com',
      fullName: 'Reporter',
    );
    final localId = await helper.saveScholarshipReport(ScholarshipReport(
      userId: userId!,
      ownerUid: 'firebase-user-1',
      scholarshipId: 'sample-scholarship',
      note: 'The deadline appears outdated.',
      createdAt: DateTime.utc(2026, 3, 1),
      pendingSync: true,
    ));

    final pending =
        await helper.getPendingScholarshipReports('firebase-user-1');
    expect(pending, hasLength(1));
    expect(pending.single.id, localId);
    expect(pending.single.pendingSync, isTrue);

    await helper.markScholarshipReportSynced(localId, 'stable-report-id');
    expect(
      await helper.getPendingScholarshipReports('firebase-user-1'),
      isEmpty,
    );
    final saved = await helper.getLocalScholarshipReports(userId: userId);
    expect(saved.single.firestoreId, 'stable-report-id');
    expect(saved.single.pendingSync, isFalse);
  });

  test('database helper persists login session state', () async {
    final helper = DatabaseHelper.instance;
    await helper.clearDatabaseForTest();

    await helper.saveSession(loggedIn: true, adminMode: true);
    final session = await helper.getSession();

    expect(session['logged_in'], isTrue);
    expect(session['admin_mode'], isTrue);
  });

  test('scholarship cache preserves metadata and replaces eligibility data',
      () async {
    final helper = DatabaseHelper.instance;
    await helper.clearDatabaseForTest();
    final scholarship = Scholarship(
      id: 'metadata-test',
      name: 'Community Scholarship',
      provider: 'Community Foundation',
      description: 'A local cached record.',
      minGwa: 2.0,
      courses: ['Computer Science'],
      yearLevels: [2, 3],
      maxIncome: 40000,
      deadline: DateTime(2027, 5, 1),
      requirements: ['Latest grades'],
      applicationUrl: 'https://example.org/apply',
      benefits: 'Tuition assistance',
      applicationPeriod: 'March to May 2027',
      sourceUrl: 'https://example.org/scholarship',
      verificationStatus: VerificationStatus.verified,
      lastVerifiedAt: DateTime(2026, 9, 1),
      descriptiveRequirements: ['Community service'],
    );

    await helper.saveScholarship(scholarship);
    await helper.saveScholarship(Scholarship(
      id: scholarship.id,
      name: scholarship.name,
      provider: scholarship.provider,
      description: scholarship.description,
      minGwa: scholarship.minGwa,
      courses: const [],
      yearLevels: const [4],
      maxIncome: scholarship.maxIncome,
      deadline: scholarship.deadline,
      requirements: const ['Updated grades'],
      applicationUrl: scholarship.applicationUrl,
    ));

    final saved = (await helper.getScholarships())
        .singleWhere((item) => item.id == scholarship.id);
    expect(saved.courses, isEmpty);
    expect(saved.yearLevels, [4]);
    expect(saved.requirements, ['Updated grades']);
    expect(saved.benefits, isEmpty);
    expect(saved.verificationStatus, VerificationStatus.unverified);
  });

  test('application status is stored per student and scholarship', () async {
    final helper = DatabaseHelper.instance;
    await helper.clearDatabaseForTest();
    await helper.saveApplicationStatus(
      userId: 1,
      scholarshipId: 'icct',
      status: ApplicationStatus.submitted,
    );

    final statuses = await helper.getApplicationStatuses(userId: 1);
    expect(statuses['icct'], ApplicationStatus.submitted);
  });

  test('database helper links Firebase users without storing passwords',
      () async {
    final helper = DatabaseHelper.instance;
    await helper.clearDatabaseForTest();

    final userId = await helper.getOrCreateFirebaseUser(
      email: 'student@example.com',
      fullName: 'Sample Student',
    );

    expect(userId, isNotNull);
    final rows = await (await helper.database).query(
      'users',
      columns: ['email', 'password_hash', 'role'],
      where: 'id = ?',
      whereArgs: [userId],
    );
    expect(rows.single['email'], 'student@example.com');
    expect(rows.single['password_hash'], isEmpty);
    expect(rows.single['role'], 'student');
    expect(await helper.getLocalFirebaseUserId('student@example.com'), userId);
  });
}
