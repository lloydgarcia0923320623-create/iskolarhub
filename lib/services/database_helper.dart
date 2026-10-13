import 'dart:async';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../screens/models/scholarship.dart';
import '../screens/models/student.dart';
import '../screens/models/income_bracket.dart';
import '../screens/models/application_status.dart';
import '../screens/models/verification_status.dart';
import '../screens/models/scholarship_report.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'iskolarhub.db');

    return openDatabase(
      path,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.update(
            'users',
            {
              'email': 'demo@iskolarhub.local',
              'password_hash': '',
            },
            where: 'password_hash = ?',
            whereArgs: ['hashed_pw_123'],
          );
        }
        if (oldVersion < 3) {
          final adminRows = await db.query(
            'users',
            columns: ['id'],
            where: 'role = ?',
            whereArgs: ['admin'],
            orderBy: 'id ASC',
          );
          for (final row in adminRows.skip(1)) {
            await db.delete(
              'users',
              where: 'id = ?',
              whereArgs: [row['id']],
            );
          }
          await db.execute(
            "CREATE UNIQUE INDEX IF NOT EXISTS one_admin_account "
            "ON users(role) WHERE role = 'admin'",
          );
        }
        if (oldVersion < 5) {
          await _ensureScholarshipColumn(
            db,
            'benefits',
            "TEXT NOT NULL DEFAULT ''",
          );
          await _ensureScholarshipColumn(
            db,
            'application_period',
            "TEXT NOT NULL DEFAULT ''",
          );
          await _ensureScholarshipColumn(
            db,
            'source_url',
            "TEXT NOT NULL DEFAULT ''",
          );
          await _ensureScholarshipColumn(
            db,
            'verification_status',
            "TEXT NOT NULL DEFAULT 'unverified'",
          );
          await _ensureScholarshipColumn(db, 'last_verified_at', 'TEXT');
          await _ensureScholarshipColumn(
            db,
            'descriptive_requirements',
            "TEXT NOT NULL DEFAULT '[]'",
          );
          await _createApplicationStatusesTable(db);
        }
        if (oldVersion < 6) {
          await db.update('users', {'password_hash': ''});
        }
        if (oldVersion < 7) {
          await _ensureColumn(
            db,
            'students',
            'income_bracket',
            'TEXT',
          );
        }
        if (oldVersion < 8) {
          await _createScholarshipReportsTable(db);
        }
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'student'
      )
    ''');

    await db.execute('''
      CREATE TABLE students (
        user_id INTEGER PRIMARY KEY,
        course TEXT NOT NULL DEFAULT '',
        year_level INTEGER NOT NULL DEFAULT 1,
        gwa REAL NOT NULL DEFAULT 0.0,
        household_income REAL NOT NULL DEFAULT 0.0,
        income_bracket TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE scholarships (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        provider TEXT NOT NULL,
        description TEXT,
        min_gwa REAL NOT NULL DEFAULT 0.0,
        max_income REAL NOT NULL DEFAULT 0.0,
        deadline TEXT NOT NULL,
        application_url TEXT,
        benefits TEXT NOT NULL DEFAULT '',
        application_period TEXT NOT NULL DEFAULT '',
        source_url TEXT NOT NULL DEFAULT '',
        verification_status TEXT NOT NULL DEFAULT 'unverified',
        last_verified_at TEXT,
        descriptive_requirements TEXT NOT NULL DEFAULT '[]'
      )
    ''');

    await db.execute('''
      CREATE TABLE scholarship_courses (
        scholarship_id TEXT NOT NULL,
        course_name TEXT NOT NULL,
        PRIMARY KEY (scholarship_id, course_name),
        FOREIGN KEY (scholarship_id) REFERENCES scholarships(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE scholarship_year_levels (
        scholarship_id TEXT NOT NULL,
        year_level INTEGER NOT NULL,
        PRIMARY KEY (scholarship_id, year_level),
        FOREIGN KEY (scholarship_id) REFERENCES scholarships(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE scholarship_requirements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scholarship_id TEXT NOT NULL,
        requirement_name TEXT NOT NULL,
        FOREIGN KEY (scholarship_id) REFERENCES scholarships(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE saved_scholarships (
        user_id INTEGER NOT NULL,
        scholarship_id TEXT NOT NULL,
        saved_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (user_id, scholarship_id),
        FOREIGN KEY (user_id) REFERENCES students(user_id) ON DELETE CASCADE,
        FOREIGN KEY (scholarship_id) REFERENCES scholarships(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE student_document_checklist (
        user_id INTEGER NOT NULL,
        scholarship_id TEXT NOT NULL,
        document_name TEXT NOT NULL,
        is_completed INTEGER NOT NULL DEFAULT 0 CHECK (is_completed IN (0, 1)),
        completed_at TEXT,
        PRIMARY KEY (user_id, scholarship_id, document_name),
        FOREIGN KEY (user_id) REFERENCES students(user_id) ON DELETE CASCADE,
        FOREIGN KEY (scholarship_id) REFERENCES scholarships(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE app_session (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        logged_in INTEGER NOT NULL DEFAULT 0 CHECK (logged_in IN (0, 1)),
        admin_mode INTEGER NOT NULL DEFAULT 0 CHECK (admin_mode IN (0, 1))
      )
    ''');
    await _createApplicationStatusesTable(db);
    await _createScholarshipReportsTable(db);
    await db.execute(
      "CREATE UNIQUE INDEX one_admin_account ON users(role) "
      "WHERE role = 'admin'",
    );

    await _seedSampleData(db);
  }

  Future<void> _createApplicationStatusesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS student_application_status (
        user_id INTEGER NOT NULL,
        scholarship_id TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'notStarted',
        updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (user_id, scholarship_id),
        FOREIGN KEY (user_id) REFERENCES students(user_id) ON DELETE CASCADE,
        FOREIGN KEY (scholarship_id) REFERENCES scholarships(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createScholarshipReportsTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scholarship_reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        owner_uid TEXT NOT NULL,
        scholarship_id TEXT NOT NULL,
        note TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        reviewer_note TEXT NOT NULL DEFAULT '',
        reviewed_at TEXT,
        firestore_id TEXT UNIQUE,
        pending_sync INTEGER NOT NULL DEFAULT 1 CHECK (pending_sync IN (0, 1))
      )
    ''');
  }

  Future<void> _ensureScholarshipColumn(
    DatabaseExecutor db,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info(scholarships)');
    if (columns.any((row) => row['name'] == column)) return;
    await db.execute('ALTER TABLE scholarships ADD COLUMN $column $definition');
  }

  Future<void> _ensureColumn(
    DatabaseExecutor db,
    String table,
    String column,
    String definition,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    if (columns.any((row) => row['name'] == column)) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  Future<void> _seedSampleData(Database db) async {
    await db.insert(
        'users',
        {
          'id': 1,
          'full_name': 'Lloyd Andrei Garcia',
          'email': 'lloyd@email.com',
          'password_hash': '',
          'role': 'student',
        },
        conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert(
        'users',
        {
          'id': 2,
          'full_name': 'Administrator',
          'email': 'admin@iskolarhub.local',
          'password_hash': '',
          'role': 'admin',
        },
        conflictAlgorithm: ConflictAlgorithm.replace);

    await db.insert(
        'students',
        {
          'user_id': 1,
          'course': 'Computer Science',
          'year_level': 2,
          'gwa': 1.75,
          'household_income': 35000.0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);

    final scholarships = [
      {
        'id': 'icct',
        'name': 'ICCT Academic Scholarship',
        'provider': 'ICCT Colleges',
        'description':
            'Financial assistance opportunity for qualified college students based on academic performance and profile information.',
        'min_gwa': 1.75,
        'max_income': 50000.0,
        'deadline': '2026-09-30',
        'application_url': 'https://www.icct.edu.ph/',
      },
      {
        'id': 'city',
        'name': 'Local Government Student Grant',
        'provider': 'Local Government Unit',
        'description':
            'A sample local government scholarship listing for demonstration and testing of the IskolarHub matching feature.',
        'min_gwa': 2.00,
        'max_income': 30000.0,
        'deadline': '2026-10-15',
        'application_url': 'https://www.gov.ph/',
      },
      {
        'id': 'tech',
        'name': 'Technology Student Assistance',
        'provider': 'Partner Foundation',
        'description':
            'Sample scholarship intended for technology-related students with qualifying academic and household-income profiles.',
        'min_gwa': 2.25,
        'max_income': 40000.0,
        'deadline': '2026-11-20',
        'application_url': 'https://www.gov.ph/',
      },
    ];

    for (final scholarship in scholarships) {
      await db.insert('scholarships', scholarship,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await db.insert('scholarship_courses',
        {'scholarship_id': 'icct', 'course_name': 'Computer Science'});
    await db.insert('scholarship_courses',
        {'scholarship_id': 'icct', 'course_name': 'Information Technology'});
    await db.insert('scholarship_courses',
        {'scholarship_id': 'tech', 'course_name': 'Computer Science'});
    await db.insert('scholarship_courses',
        {'scholarship_id': 'tech', 'course_name': 'Information Technology'});
    await db.insert('scholarship_courses',
        {'scholarship_id': 'tech', 'course_name': 'Engineering'});

    for (final year in [1, 2, 3, 4]) {
      await db.insert('scholarship_year_levels',
          {'scholarship_id': 'icct', 'year_level': year});
      await db.insert('scholarship_year_levels',
          {'scholarship_id': 'city', 'year_level': year});
    }
    for (final year in [2, 3, 4]) {
      await db.insert('scholarship_year_levels',
          {'scholarship_id': 'tech', 'year_level': year});
    }

    final requirements = {
      'icct': [
        'Updated grades / GWA',
        'Certificate of enrollment',
        'Valid school ID',
        'Proof of household income'
      ],
      'city': [
        'Grades',
        'Certificate of enrollment',
        'Barangay certificate',
        'Income document'
      ],
      'tech': [
        'Latest grades',
        'School ID',
        'Enrollment certificate',
        'Personal statement'
      ],
    };

    for (final entry in requirements.entries) {
      for (final requirement in entry.value) {
        await db.insert('scholarship_requirements', {
          'scholarship_id': entry.key,
          'requirement_name': requirement,
        });
      }
    }

    await db.insert(
        'app_session',
        {
          'id': 1,
          'logged_in': 0,
          'admin_mode': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);

    await db
        .insert('saved_scholarships', {'user_id': 1, 'scholarship_id': 'icct'});
    await db
        .insert('saved_scholarships', {'user_id': 1, 'scholarship_id': 'tech'});

    await db.insert('student_document_checklist', {
      'user_id': 1,
      'scholarship_id': 'icct',
      'document_name': 'Updated grades / GWA',
      'is_completed': 1
    });
    await db.insert('student_document_checklist', {
      'user_id': 1,
      'scholarship_id': 'icct',
      'document_name': 'Certificate of enrollment',
      'is_completed': 0
    });
    await db.insert('student_document_checklist', {
      'user_id': 1,
      'scholarship_id': 'icct',
      'document_name': 'Valid school ID',
      'is_completed': 1
    });
    await db.insert('student_document_checklist', {
      'user_id': 1,
      'scholarship_id': 'icct',
      'document_name': 'Proof of household income',
      'is_completed': 0
    });
    await db.insert('student_document_checklist', {
      'user_id': 1,
      'scholarship_id': 'tech',
      'document_name': 'Latest grades',
      'is_completed': 1
    });
    await db.insert('student_document_checklist', {
      'user_id': 1,
      'scholarship_id': 'tech',
      'document_name': 'School ID',
      'is_completed': 0
    });
  }

  Future<void> saveSession({
    required bool loggedIn,
    required bool adminMode,
  }) async {
    final db = await database;
    await db.insert(
      'app_session',
      {
        'id': 1,
        'logged_in': loggedIn ? 1 : 0,
        'admin_mode': adminMode ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, bool>> getSession() async {
    final db = await database;
    final rows = await db.query('app_session', limit: 1);
    if (rows.isEmpty) {
      return {'logged_in': false, 'admin_mode': false};
    }

    final row = rows.first;
    return {
      'logged_in': (row['logged_in'] as int) == 1,
      'admin_mode': (row['admin_mode'] as int) == 1,
    };
  }

  Future<void> saveStudentProfile(Student student,
      {required int userId}) async {
    final db = await database;
    final updated = await db.update(
      'users',
      {'full_name': student.name},
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (updated == 0) return;

    await db.insert(
      'students',
      {
        'user_id': userId,
        'course': student.course,
        'year_level': student.yearLevel,
        'gwa': student.gwa,
        'household_income':
            student.incomeBracket?.upperBound ?? student.householdIncome,
        'income_bracket': student.incomeBracket?.storageValue,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int?> getOrCreateFirebaseUser({
    required String email,
    required String fullName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return null;

    final db = await database;
    final existing = await db.query(
      'users',
      columns: ['id', 'role'],
      where: 'email = ?',
      whereArgs: [normalizedEmail],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      if (existing.first['role'] != 'student') return null;
      final id = existing.first['id'] as int;
      await db.update(
        'users',
        {'password_hash': ''},
        where: 'id = ?',
        whereArgs: [id],
      );
      return id;
    }

    return db.insert('users', {
      'full_name': fullName.trim().isEmpty ? 'New Student' : fullName.trim(),
      'email': normalizedEmail,
      'password_hash': '',
      'role': 'student',
    });
  }

  Future<int?> getLocalFirebaseUserId(String email) async {
    final db = await database;
    final rows = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ? AND role = ?',
      whereArgs: [email.trim().toLowerCase(), 'student'],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.single['id'] as int;
  }

  Future<int> saveScholarshipReport(ScholarshipReport report) async {
    final db = await database;
    return db.insert('scholarship_reports', {
      'user_id': report.userId,
      'owner_uid': report.ownerUid,
      'scholarship_id': report.scholarshipId,
      'note': report.note,
      'created_at': report.createdAt.toIso8601String(),
      'status': report.status.name,
      'reviewer_note': report.reviewerNote,
      'reviewed_at': report.reviewedAt?.toIso8601String(),
      'firestore_id': report.firestoreId,
      'pending_sync': report.pendingSync ? 1 : 0,
    });
  }

  Future<void> markScholarshipReportSynced(
    int id,
    String firestoreId,
  ) async {
    final db = await database;
    await db.update(
      'scholarship_reports',
      {'firestore_id': firestoreId, 'pending_sync': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ScholarshipReport>> getPendingScholarshipReports(
    String ownerUid,
  ) async {
    final db = await database;
    final rows = await db.query(
      'scholarship_reports',
      where: 'owner_uid = ? AND pending_sync = 1',
      whereArgs: [ownerUid],
      orderBy: 'created_at ASC',
    );
    return rows.map(_scholarshipReportFromRow).toList();
  }

  Future<List<ScholarshipReport>> getLocalScholarshipReports({
    int? userId,
  }) async {
    final db = await database;
    final rows = await db.query(
      'scholarship_reports',
      where: userId == null ? null : 'user_id = ?',
      whereArgs: userId == null ? null : [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map(_scholarshipReportFromRow).toList();
  }

  Future<void> updateLocalScholarshipReport(ScholarshipReport report) async {
    final id = report.id;
    if (id == null) return;
    final db = await database;
    await db.update(
      'scholarship_reports',
      {
        'status': report.status.name,
        'reviewer_note': report.reviewerNote,
        'reviewed_at': report.reviewedAt?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateLocalScholarshipReportByFirestoreId(
    String firestoreId,
    ScholarshipReport report,
  ) async {
    final db = await database;
    await db.update(
      'scholarship_reports',
      {
        'status': report.status.name,
        'reviewer_note': report.reviewerNote,
        'reviewed_at': report.reviewedAt?.toIso8601String(),
      },
      where: 'firestore_id = ?',
      whereArgs: [firestoreId],
    );
  }

  ScholarshipReport _scholarshipReportFromRow(Map<String, Object?> row) {
    return ScholarshipReport(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      ownerUid: row['owner_uid'] as String,
      scholarshipId: row['scholarship_id'] as String,
      note: row['note'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      status: ReportStatus.fromName(row['status'] as String?),
      reviewerNote: row['reviewer_note'] as String? ?? '',
      reviewedAt: row['reviewed_at'] == null
          ? null
          : DateTime.parse(row['reviewed_at'] as String),
      firestoreId: row['firestore_id'] as String?,
      pendingSync: (row['pending_sync'] as int) == 1,
    );
  }

  Future<Student?> getStudentProfile({required int userId}) async {
    final db = await database;
    final maps = await db.query(
      'students',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (maps.isEmpty) return null;

    final row = maps.first;
    return Student(
      name: await _getUserName(userId),
      course: row['course'] as String,
      yearLevel: row['year_level'] as int,
      gwa: (row['gwa'] as num).toDouble(),
      householdIncome: (row['household_income'] as num).toDouble(),
      incomeBracket:
          IncomeBracket.fromStorageValue(row['income_bracket'] as String?) ??
              ((row['household_income'] as num).toDouble() > 0
                  ? IncomeBracket.fromMonthlyIncome(
                      (row['household_income'] as num).toDouble())
                  : null),
    );
  }

  Future<String> _getUserName(int userId) async {
    final db = await database;
    final result = await db.query(
      'users',
      columns: ['full_name'],
      where: 'id = ?',
      whereArgs: [userId],
    );
    return result.isNotEmpty ? result.first['full_name'] as String : '';
  }

  Future<void> saveScholarship(Scholarship scholarship) async {
    final db = await database;
    await db.transaction((txn) async {
      final values = {
        'id': scholarship.id,
        'name': scholarship.name,
        'provider': scholarship.provider,
        'description': scholarship.description,
        'min_gwa': scholarship.minGwa,
        'max_income': scholarship.maxIncome,
        'deadline': scholarship.deadline.toIso8601String(),
        'application_url': scholarship.applicationUrl,
        'benefits': scholarship.benefits,
        'application_period': scholarship.applicationPeriod,
        'source_url': scholarship.sourceUrl,
        'verification_status': scholarship.verificationStatus.name,
        'last_verified_at': scholarship.lastVerifiedAt?.toIso8601String(),
        'descriptive_requirements':
            jsonEncode(scholarship.descriptiveRequirements),
      };
      final existingRows = await txn.update(
        'scholarships',
        values,
        where: 'id = ?',
        whereArgs: [scholarship.id],
      );
      if (existingRows == 0) {
        await txn.insert('scholarships', values);
      }

      await txn.delete('scholarship_courses',
          where: 'scholarship_id = ?', whereArgs: [scholarship.id]);
      await txn.delete('scholarship_year_levels',
          where: 'scholarship_id = ?', whereArgs: [scholarship.id]);
      await txn.delete('scholarship_requirements',
          where: 'scholarship_id = ?', whereArgs: [scholarship.id]);

      for (final course in scholarship.courses) {
        await txn.insert('scholarship_courses', {
          'scholarship_id': scholarship.id,
          'course_name': course,
        });
      }

      for (final year in scholarship.yearLevels) {
        await txn.insert('scholarship_year_levels', {
          'scholarship_id': scholarship.id,
          'year_level': year,
        });
      }

      for (final requirement in scholarship.requirements) {
        await txn.insert('scholarship_requirements', {
          'scholarship_id': scholarship.id,
          'requirement_name': requirement,
        });
      }
    });
  }

  Future<List<Scholarship>> getScholarships() async {
    final db = await database;

    final scholarshipRows = await db.query('scholarships');
    final allCourses = await db.query('scholarship_courses');
    final allYearLevels = await db.query('scholarship_year_levels');
    final allRequirements = await db.query('scholarship_requirements');

    final courseMap = <String, List<String>>{};
    final yearLevelMap = <String, List<int>>{};
    final requirementMap = <String, List<String>>{};

    for (final course in allCourses) {
      final scholarshipId = course['scholarship_id'] as String;
      courseMap.putIfAbsent(scholarshipId, () => []);
      courseMap[scholarshipId]!.add(course['course_name'] as String);
    }

    for (final yearLevel in allYearLevels) {
      final scholarshipId = yearLevel['scholarship_id'] as String;
      yearLevelMap.putIfAbsent(scholarshipId, () => []);
      yearLevelMap[scholarshipId]!
          .add((yearLevel['year_level'] as num).toInt());
    }

    for (final requirement in allRequirements) {
      final scholarshipId = requirement['scholarship_id'] as String;
      requirementMap.putIfAbsent(scholarshipId, () => []);
      requirementMap[scholarshipId]!
          .add(requirement['requirement_name'] as String);
    }

    final scholarships = <Scholarship>[];
    for (final row in scholarshipRows) {
      final id = row['id'] as String;
      scholarships.add(
        Scholarship(
          id: id,
          name: row['name'] as String,
          provider: row['provider'] as String,
          description: row['description'] as String? ?? '',
          minGwa: (row['min_gwa'] as num).toDouble(),
          courses: courseMap[id] ?? [],
          yearLevels: yearLevelMap[id] ?? [],
          maxIncome: (row['max_income'] as num).toDouble(),
          deadline: DateTime.parse(row['deadline'] as String),
          requirements: requirementMap[id] ?? [],
          applicationUrl: row['application_url'] as String? ?? '',
          benefits: row['benefits'] as String? ?? '',
          applicationPeriod: row['application_period'] as String? ?? '',
          sourceUrl: row['source_url'] as String? ?? '',
          verificationStatus: VerificationStatus.fromName(
              row['verification_status'] as String?),
          lastVerifiedAt:
              DateTime.tryParse(row['last_verified_at'] as String? ?? ''),
          descriptiveRequirements: List<String>.from(
              jsonDecode(row['descriptive_requirements'] as String? ?? '[]')
                  as List),
        ),
      );
    }

    return scholarships;
  }

  Future<void> deleteScholarship(String scholarshipId) async {
    final db = await database;
    await db.delete('student_document_checklist',
        where: 'scholarship_id = ?', whereArgs: [scholarshipId]);
    await db.delete('student_application_status',
        where: 'scholarship_id = ?', whereArgs: [scholarshipId]);
    await db.delete('saved_scholarships',
        where: 'scholarship_id = ?', whereArgs: [scholarshipId]);
    await db.delete('scholarship_requirements',
        where: 'scholarship_id = ?', whereArgs: [scholarshipId]);
    await db.delete('scholarship_year_levels',
        where: 'scholarship_id = ?', whereArgs: [scholarshipId]);
    await db.delete('scholarship_courses',
        where: 'scholarship_id = ?', whereArgs: [scholarshipId]);
    await db
        .delete('scholarships', where: 'id = ?', whereArgs: [scholarshipId]);
  }

  Future<void> toggleSavedScholarship(String scholarshipId,
      {required int userId}) async {
    final db = await database;
    final existing = await db.query(
      'saved_scholarships',
      where: 'user_id = ? AND scholarship_id = ?',
      whereArgs: [userId, scholarshipId],
    );

    if (existing.isNotEmpty) {
      await db.delete(
        'saved_scholarships',
        where: 'user_id = ? AND scholarship_id = ?',
        whereArgs: [userId, scholarshipId],
      );
    } else {
      await db.insert('saved_scholarships', {
        'user_id': userId,
        'scholarship_id': scholarshipId,
      });
    }
  }

  Future<Set<String>> getSavedScholarships({required int userId}) async {
    final db = await database;
    final rows = await db.query(
      'saved_scholarships',
      columns: ['scholarship_id'],
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows.map((row) => row['scholarship_id'] as String).toSet();
  }

  Future<void> toggleDocumentDone(String scholarshipId, String documentName,
      {required int userId}) async {
    final db = await database;
    final existing = await db.query(
      'student_document_checklist',
      where: 'user_id = ? AND scholarship_id = ? AND document_name = ?',
      whereArgs: [userId, scholarshipId, documentName],
    );

    if (existing.isNotEmpty) {
      final current = (existing.first['is_completed'] as int) == 1;
      await db.update(
        'student_document_checklist',
        {
          'is_completed': current ? 0 : 1,
          'completed_at': current ? null : DateTime.now().toIso8601String()
        },
        where: 'user_id = ? AND scholarship_id = ? AND document_name = ?',
        whereArgs: [userId, scholarshipId, documentName],
      );
    } else {
      await db.insert('student_document_checklist', {
        'user_id': userId,
        'scholarship_id': scholarshipId,
        'document_name': documentName,
        'is_completed': 1,
        'completed_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<Map<String, Set<String>>> getCompletedDocuments(
      {required int userId}) async {
    final db = await database;
    final rows = await db.query('student_document_checklist',
        where: 'user_id = ?', whereArgs: [userId]);

    final result = <String, Set<String>>{};
    for (final row in rows) {
      final scholarshipId = row['scholarship_id'] as String;
      final docName = row['document_name'] as String;
      final isCompleted = (row['is_completed'] as int) == 1;

      if (isCompleted) {
        result.putIfAbsent(scholarshipId, () => <String>{});
        result[scholarshipId]!.add(docName);
      }
    }

    return result;
  }

  Future<Map<String, ApplicationStatus>> getApplicationStatuses(
      {required int userId}) async {
    final db = await database;
    final rows = await db.query('student_application_status',
        where: 'user_id = ?', whereArgs: [userId]);
    return {
      for (final row in rows)
        row['scholarship_id'] as String:
            ApplicationStatus.fromName(row['status'] as String?),
    };
  }

  Future<void> saveApplicationStatus({
    required int userId,
    required String scholarshipId,
    required ApplicationStatus status,
  }) async {
    final db = await database;
    await db.insert(
      'student_application_status',
      {
        'user_id': userId,
        'scholarship_id': scholarshipId,
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearDatabaseForTest() async {
    final db = await database;
    await db.delete('student_document_checklist');
    await db.delete('student_application_status');
    await db.delete('saved_scholarships');
    await db.delete('scholarship_reports');
    await db.delete('scholarship_requirements');
    await db.delete('scholarship_year_levels');
    await db.delete('scholarship_courses');
    await db.delete('scholarships');
    await db.delete('students');
    await db.delete('users');
    await db.delete('app_session');
    await _seedSampleData(db);
  }
}
