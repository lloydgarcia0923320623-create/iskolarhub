-- IskolarHub SQLite database schema
-- This matches the app's current data model: student profile, scholarships, saved items, and checklist completion.

PRAGMA foreign_keys = ON;

CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'student' CHECK (role IN ('student', 'admin'))
);

-- Keep administrator access limited to the single seeded administrator.
CREATE UNIQUE INDEX one_admin_account ON users(role) WHERE role = 'admin';

CREATE TABLE students (
    user_id INTEGER PRIMARY KEY,
    course TEXT NOT NULL DEFAULT '',
    year_level INTEGER NOT NULL DEFAULT 1,
    gwa REAL NOT NULL DEFAULT 0.0,
    household_income REAL NOT NULL DEFAULT 0.0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE scholarships (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    provider TEXT NOT NULL,
    description TEXT,
    min_gwa REAL NOT NULL DEFAULT 0.0,
    max_income REAL NOT NULL DEFAULT 0.0,
    deadline TEXT NOT NULL,
    application_url TEXT
);

CREATE TABLE scholarship_courses (
    scholarship_id INTEGER NOT NULL,
    course_name TEXT NOT NULL,
    PRIMARY KEY (scholarship_id, course_name),
    FOREIGN KEY (scholarship_id) REFERENCES scholarships(id) ON DELETE CASCADE
);

CREATE TABLE scholarship_year_levels (
    scholarship_id INTEGER NOT NULL,
    year_level INTEGER NOT NULL,
    PRIMARY KEY (scholarship_id, year_level),
    FOREIGN KEY (scholarship_id) REFERENCES scholarships(id) ON DELETE CASCADE
);

CREATE TABLE scholarship_requirements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    scholarship_id INTEGER NOT NULL,
    requirement_name TEXT NOT NULL,
    FOREIGN KEY (scholarship_id) REFERENCES scholarships(id) ON DELETE CASCADE
);

CREATE TABLE saved_scholarships (
    user_id INTEGER NOT NULL,
    scholarship_id INTEGER NOT NULL,
    saved_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, scholarship_id),
    FOREIGN KEY (user_id) REFERENCES students(user_id) ON DELETE CASCADE,
    FOREIGN KEY (scholarship_id) REFERENCES scholarships(id) ON DELETE CASCADE
);

CREATE TABLE student_document_checklist (
    user_id INTEGER NOT NULL,
    scholarship_id INTEGER NOT NULL,
    document_name TEXT NOT NULL,
    is_completed INTEGER NOT NULL DEFAULT 0 CHECK (is_completed IN (0, 1)),
    completed_at TEXT,
    PRIMARY KEY (user_id, scholarship_id, document_name),
    FOREIGN KEY (user_id) REFERENCES students(user_id) ON DELETE CASCADE,
    FOREIGN KEY (scholarship_id) REFERENCES scholarships(id) ON DELETE CASCADE
);

-- Sample data
INSERT INTO users (full_name, email, password_hash, role)
VALUES
    ('Maria Santos', 'maria@email.com', 'hashed_pw_123', 'student'),
    ('Admin User', 'admin@iskolarhub.com', 'hashed_admin_pw', 'admin');

INSERT INTO students (user_id, course, year_level, gwa, household_income)
VALUES
    (1, 'Computer Science', 2, 1.75, 35000.00);

INSERT INTO scholarships (name, provider, description, min_gwa, max_income, deadline, application_url)
VALUES
    (
        'ICCT Academic Scholarship',
        'ICCT Colleges',
        'Financial assistance for qualified college students.',
        1.75,
        50000.00,
        '2026-09-30',
        'https://www.icct.edu.ph/'
    ),
    (
        'Local Government Student Grant',
        'Local Government Unit',
        'Grant for students in need of financial assistance.',
        2.00,
        30000.00,
        '2026-10-15',
        'https://www.gov.ph/'
    ),
    (
        'Technology Student Assistance',
        'Partner Foundation',
        'Support for technology-related students.',
        2.25,
        40000.00,
        '2026-11-20',
        'https://www.gov.ph/'
    );

INSERT INTO scholarship_courses (scholarship_id, course_name)
VALUES
    (1, 'Computer Science'),
    (1, 'Information Technology'),
    (3, 'Computer Science'),
    (3, 'Information Technology'),
    (3, 'Engineering');

INSERT INTO scholarship_year_levels (scholarship_id, year_level)
VALUES
    (1, 1), (1, 2), (1, 3), (1, 4),
    (2, 1), (2, 2), (2, 3), (2, 4),
    (3, 2), (3, 3), (3, 4);

INSERT INTO scholarship_requirements (scholarship_id, requirement_name)
VALUES
    (1, 'Updated grades / GWA'),
    (1, 'Certificate of enrollment'),
    (1, 'Valid school ID'),
    (1, 'Proof of household income'),
    (2, 'Grades'),
    (2, 'Certificate of enrollment'),
    (2, 'Barangay certificate'),
    (2, 'Income document'),
    (3, 'Latest grades'),
    (3, 'School ID'),
    (3, 'Enrollment certificate'),
    (3, 'Personal statement');

INSERT INTO saved_scholarships (user_id, scholarship_id)
VALUES
    (1, 1),
    (1, 3);

INSERT INTO student_document_checklist (user_id, scholarship_id, document_name, is_completed)
VALUES
    (1, 1, 'Updated grades / GWA', 1),
    (1, 1, 'Certificate of enrollment', 0),
    (1, 1, 'Valid school ID', 1),
    (1, 1, 'Proof of household income', 0),
    (1, 3, 'Latest grades', 1),
    (1, 3, 'School ID', 0);
