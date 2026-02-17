# Full School Seeder Documentation

## Overview
The `FullSchoolSeeder` creates a comprehensive, realistic dataset for the School Management Application with all necessary data across all models.

## What's Included

### 1. School Setup
- **1 School**: Apex International Academy
  - Complete with address, phone, email, and short code

### 2. Users (All Roles)
- **1 Proprietor**: Dr. James Proprietor
- **1 Principal**: Mrs. Sarah Principal
- **1 Bursar**: Mr. Ben Bursar
- **3 Teachers**: Teacher 1, Teacher 2, Teacher 3
- **5 Parents**: Parent 1-5

**Default Password for All Users**: `password`

### 3. Academic Structure
- **2 Sections**: Primary Section (Grades 1-6), Secondary Section (Grades 7-12)
- **3 Classes**: Grade 1, Grade 2, JSS 1
- **1 Academic Session**: 2025/2026 (for both sections)
- **3 Terms per Section**: First Term (active), Second Term, Third Term

### 4. Curriculum
- **6 Subjects**: Mathematics, English Language, Basic Science (for Grade 1 and JSS 1)
- **3 Syllabus Entries**: Topics with completion status
- **3 Lesson Plans**: Detailed lesson plans with objectives and activities

### 5. Students
- **5 Students**: All enrolled in Grade 1
  - Each linked to a parent
  - Complete with admission numbers, gender, contact info

### 6. Financial Management
- **2 Fee Types**: Tuition Fee (₦50,000), Uniform (₦15,000)
- **2 Payments**: 
  - Student 1: Full payment (₦50,000 - Cash)
  - Student 2: Partial payment (₦20,000 - Bank Transfer)
- **2 Transactions**: Corresponding income transactions recorded by bursar

### 7. Academic Assessment
- **2 Exams**: 
  - First Term Mathematics Exam (100 marks)
  - First Term English Exam (100 marks)
- **10 Exam Results**: Results for all 5 students in both subjects
  - Includes scores, grades (A-F), and remarks
  - Graded by form teacher

### 8. Assignments
- **3 Homework Assignments**:
  - Grade 1 Mathematics: Addition and Subtraction Practice
  - Grade 1 English: Reading Comprehension
  - JSS 1 Mathematics: Algebraic Expressions

### 9. Attendance
- **5 Attendance Records**: Yesterday's attendance for all Grade 1 students (all present)

### 10. Timetables
- **Complete Weekly Timetables** for:
  - Grade 1 (3 subjects × 5 days = 15 periods)
  - JSS 1 (3 subjects × 5 days = 15 periods)
- Time slots from 8:00 AM onwards

### 11. Communication
- **4 Messages**:
  - Principal → Teacher 1: Welcome message (read)
  - Teacher 1 → Principal: Reply (unread)
  - Parent 1 → Teacher 1: Homework question (read)
  - Bursar → Parent 2: Fee reminder (unread)

### 12. Notifications
- **7 Notifications**:
  - Principal: New term started (read)
  - Teacher 1: Lesson plan submission reminder (unread)
  - Parent 1: Payment received confirmation (read)
  - Parent 2: Outstanding fee balance (unread)
  - All 3 Teachers: Staff meeting announcement (unread)

## Login Credentials

All users have the password: `password`

| Role | Email | Phone |
|------|-------|-------|
| Proprietor | proprietor@apexacademy.com | 08011111111 |
| Principal | principal@apexacademy.com | 08022222222 |
| Bursar | bursar@apexacademy.com | 08033333333 |
| Teacher 1 | teacher1@apexacademy.com | 08044444441 |
| Teacher 2 | teacher2@apexacademy.com | 08044444442 |
| Teacher 3 | teacher3@apexacademy.com | 08044444443 |
| Parent 1 | parent1@apexacademy.com | 08055555551 |
| Parent 2 | parent2@apexacademy.com | 08055555552 |
| Parent 3 | parent3@apexacademy.com | 08055555553 |
| Parent 4 | parent4@apexacademy.com | 08055555554 |
| Parent 5 | parent5@apexacademy.com | 08055555555 |

## How to Run

### Method 1: Using Artisan Command
```bash
cd backend
php artisan db:seed --class=FullSchoolSeeder
```

### Method 2: Fresh Migration with Seeding
```bash
cd backend
php artisan migrate:fresh --seed
```
*Note: This will drop all tables and recreate them. Make sure to update `DatabaseSeeder.php` to call `FullSchoolSeeder`.*

### Method 3: Include in DatabaseSeeder
Edit `backend/database/seeders/DatabaseSeeder.php`:
```php
public function run()
{
    $this->call([
        FullSchoolSeeder::class,
    ]);
}
```

Then run:
```bash
php artisan db:seed
```

## Database Tables Populated

✅ schools
✅ users
✅ sections
✅ user_section (pivot)
✅ academic_sessions
✅ terms
✅ classes
✅ subjects
✅ students
✅ fees
✅ payments
✅ transactions
✅ attendance
✅ exams
✅ exam_results
✅ homework
✅ lesson_plans
✅ syllabuses
✅ timetables
✅ messages
✅ notifications

## Testing the Data

After seeding, you can test various features:

1. **Login as different roles** to see role-based dashboards
2. **View students** in Grade 1 and their details
3. **Check fee payments** and outstanding balances
4. **Review exam results** and grades
5. **View timetables** for different classes
6. **Check messages** between users
7. **See notifications** for different user types
8. **Review homework assignments** and due dates
9. **Check lesson plans** and syllabus progress
10. **View attendance records**

## Data Relationships

The seeder ensures all relationships are properly established:
- Students → Parents (each student has a parent)
- Classes → Teachers (form teachers assigned)
- Subjects → Teachers (subject teachers assigned)
- Subjects → Classes (subjects belong to classes)
- Fees → Classes (fees are class-specific)
- Payments → Students & Fees
- Transactions → Students, Sessions, Terms
- Exams → Subjects, Classes, Terms, Sessions
- Exam Results → Exams, Students
- Homework → Classes, Subjects, Teachers
- Lesson Plans → Classes, Subjects, Teachers
- Timetables → Classes, Subjects, Teachers
- Messages → Users (sender/recipient)
- Notifications → Users

## Notes

- All dates are relative to the current date using Carbon
- The first term is set as active
- Exam dates are set 30+ days in the future
- Homework due dates are 5-10 days in the future
- Attendance is recorded for yesterday
- Grading system: A (90+), B (80-89), C (70-79), D (60-69), E (50-59), F (<50)

## Extending the Seeder

To add more data:
1. Increase the loop counters for teachers, parents, or students
2. Add more classes (Grade 3, Grade 4, etc.)
3. Add more subjects per class
4. Create additional homework, exams, or lesson plans
5. Add more messages and notifications

## Troubleshooting

If you encounter errors:
1. Ensure all migrations have been run: `php artisan migrate`
2. Check that all model relationships are properly defined
3. Verify that foreign key constraints match your database schema
4. Clear cache if needed: `php artisan cache:clear`
