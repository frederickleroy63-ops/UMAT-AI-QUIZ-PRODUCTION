-- =====================================================
-- UMAT AI Quiz System — Database Setup Script
-- Run this before starting the backend for the first time
-- =====================================================

-- Database is created by Railway PostgreSQL service
-- Tables are auto-created by Spring Boot JPA (ddl-auto=update)
-- This script is for manual setup or reference only.

-- ── STUDENTS ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS students (
  id                BIGSERIAL PRIMARY KEY,
  reference_number  VARCHAR(20) NOT NULL UNIQUE,
  full_name         VARCHAR(100) NOT NULL,
  course            VARCHAR(100) NOT NULL,
  level             INT NOT NULL,
  email             VARCHAR(150) NOT NULL,
  active            BOOLEAN NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login        TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_students_ref ON students (reference_number);
CREATE INDEX IF NOT EXISTS idx_students_course_level ON students (course, level);

-- ── LECTURERS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS lecturers (
  id            BIGSERIAL PRIMARY KEY,
  username      VARCHAR(50) NOT NULL UNIQUE,
  password      VARCHAR(255) NOT NULL,
  full_name     VARCHAR(100) NOT NULL,
  department    VARCHAR(100) NOT NULL,
  email         VARCHAR(150) NOT NULL,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login    TIMESTAMP
);

-- ── QUIZZES ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS quizzes (
  id                BIGSERIAL PRIMARY KEY,
  title             VARCHAR(200) NOT NULL,
  course            VARCHAR(100) NOT NULL,
  level             INT NOT NULL,
  duration_minutes  INT NOT NULL,
  scheduled_start   TIMESTAMP NOT NULL,
  scheduled_end     TIMESTAMP,
  active            BOOLEAN NOT NULL DEFAULT TRUE,
  created_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_by        VARCHAR(100)
);

CREATE INDEX IF NOT EXISTS idx_quizzes_course_level ON quizzes (course, level);

-- ── QUESTIONS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS questions (
  id              BIGSERIAL PRIMARY KEY,
  quiz_id         BIGINT NOT NULL,
  question_text   TEXT NOT NULL,
  option_a        VARCHAR(500) NOT NULL,
  option_b        VARCHAR(500) NOT NULL,
  option_c        VARCHAR(500) NOT NULL,
  option_d        VARCHAR(500) NOT NULL,
  correct_answer  VARCHAR(1) NOT NULL,
  marks           INT DEFAULT 1,
  order_index     INT,
  FOREIGN KEY (quiz_id) REFERENCES quizzes(id) ON DELETE CASCADE
);

-- ── QUIZ ATTEMPTS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS quiz_attempts (
  id                  BIGSERIAL PRIMARY KEY,
  student_id          BIGINT NOT NULL,
  quiz_id             BIGINT NOT NULL,
  score               INT,
  total_marks         INT,
  percentage          DOUBLE PRECISION,
  status              VARCHAR(20) DEFAULT 'IN_PROGRESS' CHECK (status IN ('IN_PROGRESS','SUBMITTED','AUTO_SUBMITTED','FLAGGED')),
  cheating_score      INT DEFAULT 0,
  flagged_for_review  BOOLEAN DEFAULT FALSE,
  started_at          TIMESTAMP,
  submitted_at        TIMESTAMP,
  recording_path      VARCHAR(500),
  recording_url       VARCHAR(500),
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (quiz_id) REFERENCES quizzes(id),
  UNIQUE (student_id, quiz_id)
);

CREATE INDEX IF NOT EXISTS idx_quiz_attempts_quiz ON quiz_attempts (quiz_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_student ON quiz_attempts (student_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_flagged ON quiz_attempts (flagged_for_review);

-- ── STUDENT ANSWERS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS student_answers (
  id               BIGSERIAL PRIMARY KEY,
  attempt_id       BIGINT NOT NULL,
  question_id      BIGINT NOT NULL,
  selected_answer  VARCHAR(1),
  is_correct       BOOLEAN,
  marks_awarded    INT DEFAULT 0,
  FOREIGN KEY (attempt_id) REFERENCES quiz_attempts(id) ON DELETE CASCADE,
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

-- ── CHEATING EVENTS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cheating_events (
  id               BIGSERIAL PRIMARY KEY,
  attempt_id       BIGINT NOT NULL,
  event_type       VARCHAR(50) NOT NULL CHECK (event_type IN ('NO_FACE_DETECTED','MULTIPLE_FACES','LOOKING_AWAY','PHONE_DETECTED',
                        'TAB_SWITCH','FULLSCREEN_EXIT','SCREENSHOT_DETECTED',
                        'COPY_PASTE_ATTEMPT','DEVTOOLS_OPEN','ESC_PRESSED')),
  description      VARCHAR(500),
  severity_points  INT,
  occurred_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  snapshot_path    VARCHAR(500),
  FOREIGN KEY (attempt_id) REFERENCES quiz_attempts(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_cheating_events_attempt ON cheating_events (attempt_id);

-- ── SAMPLE DATA (optional) ────────────────────────────────────
-- The DataSeeder.java class auto-inserts demo data on first run.
-- You can also run this manually:

/*
INSERT INTO students (reference_number, full_name, course, level, email) VALUES
  ('UMAT/CS/21/0042', 'Ama Korantema',  'Computer Science',      300, 'ama@umat.edu.gh'),
  ('UMAT/CS/21/0043', 'Kojo Asante',    'Computer Science',      300, 'kojo@umat.edu.gh'),
  ('UMAT/ME/22/0010', 'Fatima Hassan',  'Mining Engineering',    200, 'fatima@umat.edu.gh'),
  ('UMAT/EE/20/0055', 'Emeka Eze',      'Electrical Engineering', 400, 'emeka@umat.edu.gh');

-- Lecturer: password = umat2026 (BCrypt)
INSERT INTO lecturers (username, password, full_name, department, email) VALUES
  ('lecturer', '$2a$10$xK7K6R5cZQf9J9A4rD2E8.n9J3uT8jL2kpO1mH4nB7vC5wX0yZ3se',
   'Dr. Emmanuel Boateng', 'Computer Science', 'e.boateng@umat.edu.gh');
*/

SELECT 'UMAT Quiz Database setup complete!' AS status;

-- ── ANNOUNCEMENTS (added in v2.0) ─────────────────────────────
CREATE TABLE IF NOT EXISTS announcements (
  id              BIGSERIAL PRIMARY KEY,
  title           VARCHAR(200) NOT NULL,
  body            TEXT NOT NULL,
  target_course   VARCHAR(100),
  target_level    INT,
  lecturer_id     BIGINT,
  lecturer_name   VARCHAR(100),
  posted_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  pinned          BOOLEAN DEFAULT FALSE,
  type            VARCHAR(20) DEFAULT 'GENERAL' CHECK (type IN ('GENERAL','QUIZ_INSTRUCTION','RESULT_NOTICE','URGENT'))
);

CREATE INDEX IF NOT EXISTS idx_announcements_course ON announcements (target_course);
CREATE INDEX IF NOT EXISTS idx_announcements_level ON announcements (target_level);

-- ── QUIZ ENROLLMENTS (added in v2.0) ──────────────────────────
CREATE TABLE IF NOT EXISTS quiz_enrollments (
  id          BIGSERIAL PRIMARY KEY,
  student_id  BIGINT NOT NULL,
  quiz_id     BIGINT NOT NULL,
  enrolled_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status      VARCHAR(10) DEFAULT 'ENROLLED' CHECK (status IN ('ENROLLED','COMPLETED','ABSENT')),
  UNIQUE (student_id, quiz_id),
  FOREIGN KEY (student_id) REFERENCES students(id),
  FOREIGN KEY (quiz_id) REFERENCES quizzes(id)
);

-- ── AI EXPLANATIONS (added in v2.0) ───────────────────────────
CREATE TABLE IF NOT EXISTS ai_explanations (
  id                    BIGSERIAL PRIMARY KEY,
  attempt_id            BIGINT NOT NULL,
  question_id           BIGINT NOT NULL,
  correct_explanation   TEXT,
  wrong_explanation     TEXT,
  student_answer        VARCHAR(1),
  correct_answer        VARCHAR(1),
  was_correct           BOOLEAN,
  generated_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (attempt_id) REFERENCES quiz_attempts(id) ON DELETE CASCADE,
  FOREIGN KEY (question_id) REFERENCES questions(id),
  UNIQUE (attempt_id, question_id)
);

-- Alter students table to add new profile fields (if upgrading)
ALTER TABLE students
  ADD COLUMN IF NOT EXISTS program VARCHAR(200),
  ADD COLUMN IF NOT EXISTS department VARCHAR(100),
  ADD COLUMN IF NOT EXISTS enrollment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Alter quizzes to add new fields
ALTER TABLE quizzes
  ADD COLUMN IF NOT EXISTS enrollment_required BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS description TEXT;
