-- School Management App - Mock Data Generation Script
-- This script creates a complete school ecosystem with all linked entities.
-- Paste this into your MySQL Workbench to populate your database.

SET @school_id = 'SCH-2025-001';
SET @proprietor_id = 'USR-PROP-001';
SET @principal_id = 'USR-PRIN-001';
SET @bursar_id = 'USR-BURS-001';
SET @teacher_a_id = 'USR-TCHR-001';
SET @teacher_b_id = 'USR-TCHR-002';
SET @parent_a_id = 'USR-PRNT-001';
SET @parent_b_id = 'USR-PRNT-002';
SET @section_id = 'SEC-PRIM-001';
SET @session_id = 'SES-2025-001';
SET @term_id = 'TRM-001';
SET @class_id = 'CLS-G5-001';
SET @student_a_id = 'STU-001';
SET @student_b_id = 'STU-002';

-- 1. Create School
INSERT INTO schools (id, name, address, email, phone_number, created_at, updated_at)
VALUES (
    @school_id, 
    'Prestige International Academy', 
    '123 Excellence Blvd, Knowledge City', 
    'info@prestigeacademy.com', 
    '+1234567890', 
    NOW(), 
    NOW()
);

-- 2. Create Users (Proprietor, Principal, Bursar, Teachers, Parents)
-- Password 'password123' is hashed (dummy hash for example)
INSERT INTO users (id, pretty_id, full_name, email, phone_number, address, role, school_id, password, is_active, created_at, updated_at) VALUES
(@proprietor_id, 'PROP001', 'Dr. Samuel Owner', 'owner@prestige.com', '08011111111', 'Admin Block A', 'proprietor', @school_id, '$2y$10$dummyhashpassword123', 1, NOW(), NOW()),
(@principal_id, 'PRIN001', 'Mrs. Sarah Admin', 'principal@prestige.com', '08022222222', 'Admin Block B', 'principal', @school_id, '$2y$10$dummyhashpassword123', 1, NOW(), NOW()),
(@bursar_id, 'BURS001', 'Mr. John Finance', 'bursar@prestige.com', '08033333333', 'Accounts Office', 'bursar', @school_id, '$2y$10$dummyhashpassword123', 1, NOW(), NOW()),
(@teacher_a_id, 'TCHR001', 'Mr. Alex Tech', 'alex@prestige.com', '08044444444', 'Staff Room', 'teacher', @school_id, '$2y$10$dummyhashpassword123', 1, NOW(), NOW()),
(@teacher_b_id, 'TCHR002', 'Ms. Mary English', 'mary@prestige.com', '08055555555', 'Staff Room', 'teacher', @school_id, '$2y$10$dummyhashpassword123', 1, NOW(), NOW()),
(@parent_a_id, 'PRNT001', 'Chief Obi Okon', 'parent1@gmail.com', '08066666666', 'Lagos, Nigeria', 'parent', @school_id, '$2y$10$dummyhashpassword123', 1, NOW(), NOW()),
(@parent_b_id, 'PRNT002', 'Mrs. Funke Ade', 'parent2@gmail.com', '08077777777', 'Abuja, Nigeria', 'parent', @school_id, '$2y$10$dummyhashpassword123', 1, NOW(), NOW());

-- 3. Create Section
INSERT INTO sections (id, school_id, section_name, about_section, created_at, updated_at)
VALUES (@section_id, @school_id, 'Primary Section', 'Grades 1-6', NOW(), NOW());

-- 4. Create Academic Session
INSERT INTO academic_sessions (id, school_id, section_id, session_name, start_date, end_date, is_active, created_at, updated_at)
VALUES (@session_id, @school_id, @section_id, '2025/2026', '2025-09-01', '2026-07-30', 1, NOW(), NOW());

-- 5. Create Term
INSERT INTO terms (id, school_id, section_id, session_id, term_name, start_date, end_date, is_active, created_at, updated_at)
VALUES (@term_id, @school_id, @section_id, @session_id, 'First Term', '2025-09-01', '2025-12-15', 1, NOW(), NOW());

-- 6. Create Class
INSERT INTO classes (id, school_id, section_id, class_name, form_teacher_id, capacity, is_active, created_at, updated_at)
VALUES (@class_id, @school_id, @section_id, 'Grade 5 Gold', @teacher_a_id, 30, 1, NOW(), NOW());

-- 7. Create Subjects
INSERT INTO subjects (id, school_id, class_id, teacher_id, name, code, created_at, updated_at) VALUES
('SUB-001', @school_id, @class_id, @teacher_a_id, 'Mathematics', 'MAT501', NOW(), NOW()),
('SUB-002', @school_id, @class_id, @teacher_b_id, 'English Language', 'ENG501', NOW(), NOW()),
('SUB-003', @school_id, @class_id, @teacher_a_id, 'Basic Science', 'BSC501', NOW(), NOW());

-- 8. Create Students
INSERT INTO students (id, school_id, section_ids, class_id, parent_id, user_id, student_name, admission_number, gender, date_of_birth, address, is_active, created_at, updated_at) VALUES
(@student_a_id, @school_id, JSON_ARRAY(@section_id), @class_id, @parent_a_id, NULL, 'Emeka Okon', 'ADM/2025/001', 'Male', '2015-05-12', 'Lagos', 1, NOW(), NOW()),
(@student_b_id, @school_id, JSON_ARRAY(@section_id), @class_id, @parent_b_id, NULL, 'Bola Ade', 'ADM/2025/002', 'Female', '2016-02-20', 'Abuja', 1, NOW(), NOW());

-- 9. Create Fees
INSERT INTO fees (id, school_id, section_id, session_id, term_id, class_id, name, amount, due_date, description, created_at, updated_at) VALUES
('FEE-001', @school_id, @section_id, @session_id, @term_id, NULL, 'General Tuition', 150000.00, '2025-09-01', 'Termly tuition fee', NOW(), NOW()),
('FEE-002', @school_id, @section_id, @session_id, @term_id, @class_id, 'Grade 5 Textbooks', 25000.00, '2025-09-10', 'Math & English textbooks', NOW(), NOW());

-- 10. Create Transactions (Payments)
INSERT INTO transactions (id, school_id, student_id, parent_id, amount, category, transaction_type, payment_method, reference, status, created_at, updated_at) VALUES
('TRX-001', @school_id, @student_a_id, @parent_a_id, 150000.00, 'General Tuition', 'credit', 'bank_transfer', 'REF-001122', 'successful', NOW(), NOW()),
('TRX-002', @school_id, @student_b_id, @parent_b_id, 50000.00, 'General Tuition', 'credit', 'cash', 'REF-003344', 'successful', NOW(), NOW()); -- Partial payment

-- 11. Create Attendance (One week sample)
INSERT INTO attendance (id, school_id, class_id, student_id, date, status, marked_by, created_at, updated_at) VALUES
('ATT-001', @school_id, @class_id, @student_a_id, CURDATE(), 'present', @teacher_a_id, NOW(), NOW()),
('ATT-002', @school_id, @class_id, @student_b_id, CURDATE(), 'present', @teacher_a_id, NOW(), NOW()),
('ATT-003', @school_id, @class_id, @student_a_id, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'present', @teacher_a_id, NOW(), NOW()),
('ATT-004', @school_id, @class_id, @student_b_id, DATE_SUB(CURDATE(), INTERVAL 1 DAY), 'absent', @teacher_a_id, NOW(), NOW());

-- 12. Link Users to Section (Many-to-Many usually, but assuming simple 1:M via user table for now if applicable, else JSON)
-- Updating users table with JSON references if your schema supports it, or created dedicated link tables. 
-- Assuming 'assigned_sections' in users table is JSON or similar:
UPDATE users SET assigned_sections = JSON_ARRAY(@section_id), assigned_schools = JSON_ARRAY(@school_id) WHERE id IN (@principal_id, @bursar_id, @teacher_a_id, @teacher_b_id);

-- Output success message
SELECT 'Mock School Data Generated Successfully' AS status;
