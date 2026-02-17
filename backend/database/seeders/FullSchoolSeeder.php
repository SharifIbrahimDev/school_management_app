<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use App\Models\School;
use App\Models\User;
use App\Models\Section;
use App\Models\ClassModel;
use App\Models\Student;
use App\Models\AcademicSession;
use App\Models\Term;
use App\Models\Subject;
use App\Models\Fee;
use App\Models\Payment;
use App\Models\Attendance;
use App\Models\Transaction;
use App\Models\Exam;
use App\Models\ExamResult;
use App\Models\Homework;
use App\Models\LessonPlan;
use App\Models\Message;
use App\Models\Notification;
use App\Models\Syllabus;
use App\Models\Timetable;
use Carbon\Carbon;

class FullSchoolSeeder extends Seeder
{
    public function run()
    {
        // 1. Create School
        $school = School::create([
            'name' => 'Apex International Academy',
            'short_code' => 'AIA',
            'address' => '42 Knowledge Avenue, Scholastic City',
            'phone' => '+234 800 123 4567',
            'email' => 'admin@apexacademy.com',
            'is_active' => true,
        ]);

        $this->command->info("School '{$school->name}' created.");

        // 2. Create Types of Users (Proprietor, Principal, Bursar)
        // Password for all: 'password'
        $commonPassword = Hash::make('password');

        $proprietor = User::create([
            'school_id' => $school->id,
            'full_name' => 'Dr. James Proprietor',
            'email' => 'proprietor@apexacademy.com',
            'phone_number' => '08011111111',
            'password' => $commonPassword,
            'role' => 'proprietor',
            'is_active' => true,
            'email_verified_at' => now(),
        ]);

        $principal = User::create([
            'school_id' => $school->id,
            'full_name' => 'Mrs. Sarah Principal',
            'email' => 'principal@apexacademy.com',
            'phone_number' => '08022222222',
            'password' => $commonPassword,
            'role' => 'principal',
            'is_active' => true,
            'email_verified_at' => now(),
        ]);

        $bursar = User::create([
            'school_id' => $school->id,
            'full_name' => 'Mr. Ben Bursar',
            'email' => 'bursar@apexacademy.com',
            'phone_number' => '08033333333',
            'password' => $commonPassword,
            'role' => 'bursar',
            'is_active' => true,
            'email_verified_at' => now(),
        ]);

        // Create Teachers
        $teachers = [];
        for ($i = 1; $i <= 3; $i++) {
            $teachers[] = User::create([
                'school_id' => $school->id,
                'full_name' => "Teacher $i",
                'email' => "teacher$i@apexacademy.com",
                'phone_number' => "0804444444$i",
                'password' => $commonPassword,
                'role' => 'teacher',
                'is_active' => true,
                'email_verified_at' => now(),
            ]);
        }

        // Create Parents
        $parents = [];
        for ($i = 1; $i <= 5; $i++) {
            $parents[] = User::create([
                'school_id' => $school->id,
                'full_name' => "Parent $i",
                'email' => "parent$i@apexacademy.com",
                'phone_number' => "0805555555$i",
                'password' => $commonPassword,
                'role' => 'parent',
                'is_active' => true,
                'email_verified_at' => now(),
            ]);
        }
        
        $this->command->info('Users created: Proprietor, Principal, Bursar, 3 Teachers, 5 Parents.');

        // 3. Create Sections (Primary, Secondary)
        $primarySection = Section::create([
            'school_id' => $school->id,
            'section_name' => 'Primary Section',
            'description' => 'Grades 1-6',
        ]);

        $secondarySection = Section::create([
            'school_id' => $school->id,
            'section_name' => 'Secondary Section',
            'description' => 'Grades 7-12',
        ]);

        // Assign Principal/Bursar to Sections (Pivot table: user_section)
        DB::table('user_section')->insert([
            ['user_id' => $principal->id, 'section_id' => $primarySection->id, 'created_at' => now(), 'updated_at' => now()],
            ['user_id' => $principal->id, 'section_id' => $secondarySection->id, 'created_at' => now(), 'updated_at' => now()],
            ['user_id' => $bursar->id, 'section_id' => $primarySection->id, 'created_at' => now(), 'updated_at' => now()],
            ['user_id' => $bursar->id, 'section_id' => $secondarySection->id, 'created_at' => now(), 'updated_at' => now()],
            // Assign Teachers to Sections for browsing
            ['user_id' => $teachers[0]->id, 'section_id' => $primarySection->id, 'created_at' => now(), 'updated_at' => now()],
            ['user_id' => $teachers[1]->id, 'section_id' => $secondarySection->id, 'created_at' => now(), 'updated_at' => now()],
        ]);
        
        $this->command->info('Sections created and staff assigned.');

        // 4. Create Academic Sessions & Terms
        $primarySession = AcademicSession::create([
            'school_id' => $school->id,
            'section_id' => $primarySection->id,
            'session_name' => '2025/2026',
            'start_date' => Carbon::now()->subMonths(4),
            'end_date' => Carbon::now()->addMonths(8),
            'is_active' => true,
        ]);

        $secondarySession = AcademicSession::create([
            'school_id' => $school->id,
            'section_id' => $secondarySection->id,
            'session_name' => '2025/2026',
            'start_date' => Carbon::now()->subMonths(4),
            'end_date' => Carbon::now()->addMonths(8),
            'is_active' => true,
        ]);

        $termNames = ['First Term', 'Second Term', 'Third Term'];
        $primaryTerms = [];
        foreach ($termNames as $index => $name) {
            $pTerm = Term::create([
                'school_id' => $school->id,
                'section_id' => $primarySection->id,
                'session_id' => $primarySession->id,
                'term_name' => $name,
                'start_date' => Carbon::now()->addMonths($index * 4),
                'end_date' => Carbon::now()->addMonths(($index * 4) + 3),
                'is_active' => $index == 0, // First term active
            ]);
            $primaryTerms[] = $pTerm;
            
             Term::create([
                'school_id' => $school->id,
                'section_id' => $secondarySection->id,
                'session_id' => $secondarySession->id,
                'term_name' => $name,
                'start_date' => Carbon::now()->addMonths($index * 4),
                'end_date' => Carbon::now()->addMonths(($index * 4) + 3),
                'is_active' => $index == 0,
            ]);
        }
        $activePrimaryTerm = $primaryTerms[0];
        
        $this->command->info('Academic Sessions and Terms created.');

        // 5. Create Classes
        $grade1 = ClassModel::create([
            'school_id' => $school->id,
            'section_id' => $primarySection->id,
            'class_name' => 'Grade 1',
            'description' => 'First Year Primary',
            'form_teacher_id' => $teachers[0]->id,
            'capacity' => 30,
            'is_active' => true,
        ]);
        
        $grade2 = ClassModel::create([
            'school_id' => $school->id,
            'section_id' => $primarySection->id,
            'class_name' => 'Grade 2',
            'description' => 'Second Year Primary',
            'form_teacher_id' => $teachers[0]->id,
            'capacity' => 30,
            'is_active' => true,
        ]);
        
        $jss1 = ClassModel::create([
            'school_id' => $school->id,
            'section_id' => $secondarySection->id,
            'class_name' => 'JSS 1',
            'description' => 'Junior Secondary School 1',
            'form_teacher_id' => $teachers[1]->id,
            'capacity' => 40,
            'is_active' => true,
        ]);

        // 6. Create Subjects
        $subjects = ['Mathematics', 'English Language', 'Basic Science'];
        foreach ($subjects as $subName) {
            Subject::create([
                'school_id' => $school->id,
                'class_id' => $grade1->id,
                'name' => $subName,
                'code' => strtoupper(substr($subName, 0, 3)),
                'teacher_id' => $teachers[0]->id,
            ]);
             Subject::create([
                'school_id' => $school->id,
                'class_id' => $jss1->id,
                'name' => $subName,
                'code' => strtoupper(substr($subName, 0, 3)),
                'teacher_id' => $teachers[1]->id,
            ]);
        }
        
        $this->command->info('Classes and Subjects created.');

        // 7. Create Fees
        $tuitionFee = Fee::create([
            'school_id' => $school->id,
            'section_id' => $primarySection->id,
            'session_id' => $primarySession->id,
            'term_id' => $activePrimaryTerm->id,
            'class_id' => $grade1->id,
            'fee_name' => 'Tuition Fee',
            'amount' => 50000.00,
            'fee_scope' => 'class',
            'description' => 'Standard Tuition',
        ]);
        
        $uniformFee = Fee::create([
            'school_id' => $school->id,
            'section_id' => $primarySection->id,
            'session_id' => $primarySession->id,
            'term_id' => $activePrimaryTerm->id,
            'class_id' => $grade1->id,
            'fee_name' => 'Uniform',
            'amount' => 15000.00,
            'fee_scope' => 'class',
            'description' => 'School Uniform Set',
        ]);

        // 8. Create Students and Link to Parents
        for ($i = 0; $i < 5; $i++) {
            $student = Student::create([
                'school_id' => $school->id,
                'section_id' => $primarySection->id,
                'class_id' => $grade1->id,
                'parent_id' => $parents[$i]->id,
                'student_name' => "Student {$grade1->class_name} - " . ($i + 1),
                'admission_number' => "ADM/2025/00" . ($i + 1),
                'gender' => $i % 2 == 0 ? 'male' : 'female',
                'parent_name' => $parents[$i]->full_name,
                'parent_email' => $parents[$i]->email,
                'parent_phone' => $parents[$i]->phone_number,
                'is_active' => true,
            ]);
            
            // 9. Records Payments & Transactions
            if ($i == 0) {
                 Payment::create([
                    'student_id' => $student->id,
                    'fee_id' => $tuitionFee->id,
                    'amount' => 50000.00,
                    'payment_method' => 'cash',
                    'reference' => 'REF-' . uniqid(),
                    'status' => 'success',
                    'paid_at' => now(),
                 ]);
                 
                 // Also record as Transaction
                 Transaction::create([
                    'school_id' => $school->id,
                    'section_id' => $primarySection->id,
                    'session_id' => $primarySession->id,
                    'term_id' => $activePrimaryTerm->id,
                    'student_id' => $student->id,
                    'transaction_type' => 'income',
                    'amount' => 50000.00,
                    'payment_method' => 'cash',
                    'category' => 'Fees',
                    'description' => "Tuition payment for {$student->student_name}",
                    'reference_number' => 'REF-' . uniqid(),
                    'transaction_date' => now(),
                    'recorded_by' => $bursar->id,
                 ]);
            }
            
            if ($i == 1) {
                Payment::create([
                    'student_id' => $student->id,
                    'fee_id' => $tuitionFee->id,
                    'amount' => 20000.00,
                    'payment_method' => 'bank_transfer',
                    'reference' => 'REF-' . uniqid(),
                    'status' => 'success',
                    'paid_at' => now(),
                 ]);

                 Transaction::create([
                    'school_id' => $school->id,
                    'section_id' => $primarySection->id,
                    'session_id' => $primarySession->id,
                    'term_id' => $activePrimaryTerm->id,
                    'student_id' => $student->id,
                    'transaction_type' => 'income',
                    'amount' => 20000.00,
                    'payment_method' => 'bank_transfer',
                    'category' => 'Fees',
                    'description' => "Partial tuition payment for {$student->student_name}",
                    'reference_number' => 'REF-' . uniqid(),
                    'transaction_date' => now(),
                    'recorded_by' => $bursar->id,
                 ]);
            }
            
            // 10. Create Attendance
            Attendance::create([
                'school_id' => $school->id,
                'student_id' => $student->id,
                'class_id' => $grade1->id,
                'date' => Carbon::yesterday()->format('Y-m-d'),
                'status' => 'present',
                'recorded_by' => $teachers[0]->id,
            ]);
        }
        
        $this->command->info('Students, Fees, Payments, and Attendance created.');
        
        // 11. Create Exams
        $mathExam = Exam::create([
            'school_id' => $school->id,
            'subject_id' => Subject::where('class_id', $grade1->id)->where('name', 'Mathematics')->first()->id,
            'class_id' => $grade1->id,
            'term_id' => $activePrimaryTerm->id,
            'session_id' => $primarySession->id,
            'title' => 'First Term Mathematics Exam',
            'max_score' => 100,
            'date' => Carbon::now()->addDays(30),
        ]);
        
        $englishExam = Exam::create([
            'school_id' => $school->id,
            'subject_id' => Subject::where('class_id', $grade1->id)->where('name', 'English Language')->first()->id,
            'class_id' => $grade1->id,
            'term_id' => $activePrimaryTerm->id,
            'session_id' => $primarySession->id,
            'title' => 'First Term English Exam',
            'max_score' => 100,
            'date' => Carbon::now()->addDays(32),
        ]);
        
        // 12. Create Exam Results for students
        $students = Student::where('class_id', $grade1->id)->get();
        foreach ($students as $index => $student) {
            // Math results
            ExamResult::create([
                'exam_id' => $mathExam->id,
                'student_id' => $student->id,
                'score' => 70 + ($index * 5), // Varying scores
                'grade' => $this->calculateGrade(70 + ($index * 5)),
                'remark' => 'Good performance',
                'graded_by' => $teachers[0]->id,
            ]);
            
            // English results
            ExamResult::create([
                'exam_id' => $englishExam->id,
                'student_id' => $student->id,
                'score' => 65 + ($index * 6),
                'grade' => $this->calculateGrade(65 + ($index * 6)),
                'remark' => 'Satisfactory',
                'graded_by' => $teachers[0]->id,
            ]);
        }
        
        $this->command->info('Exams and Exam Results created.');
        
        // 13. Create Homework
        $mathSubject = Subject::where('class_id', $grade1->id)->where('name', 'Mathematics')->first();
        $englishSubject = Subject::where('class_id', $grade1->id)->where('name', 'English Language')->first();
        
        Homework::create([
            'school_id' => $school->id,
            'class_id' => $grade1->id,
            'section_id' => $primarySection->id,
            'subject_id' => $mathSubject->id,
            'teacher_id' => $teachers[0]->id,
            'title' => 'Addition and Subtraction Practice',
            'description' => 'Complete exercises 1-20 on page 45 of your mathematics textbook.',
            'due_date' => Carbon::now()->addDays(7),
            'attachment_url' => null,
        ]);
        
        Homework::create([
            'school_id' => $school->id,
            'class_id' => $grade1->id,
            'section_id' => $primarySection->id,
            'subject_id' => $englishSubject->id,
            'teacher_id' => $teachers[0]->id,
            'title' => 'Reading Comprehension',
            'description' => 'Read the story "The Little Red Hen" and answer the questions at the end.',
            'due_date' => Carbon::now()->addDays(5),
            'attachment_url' => null,
        ]);
        
        Homework::create([
            'school_id' => $school->id,
            'class_id' => $jss1->id,
            'section_id' => $secondarySection->id,
            'subject_id' => Subject::where('class_id', $jss1->id)->where('name', 'Mathematics')->first()->id,
            'teacher_id' => $teachers[1]->id,
            'title' => 'Algebraic Expressions',
            'description' => 'Solve all problems in Chapter 3, Section 2.',
            'due_date' => Carbon::now()->addDays(10),
            'attachment_url' => null,
        ]);
        
        $this->command->info('Homework assignments created.');
        
        // 14. Create Lesson Plans
        LessonPlan::create([
            'school_id' => $school->id,
            'section_id' => $primarySection->id,
            'class_id' => $grade1->id,
            'subject_id' => $mathSubject->id,
            'teacher_id' => $teachers[0]->id,
            'title' => 'Introduction to Addition',
            'content' => 'Objectives: Students will learn basic addition with single digits. Activities: Use counting blocks, group work, and worksheets.',
            'week_number' => 1,
            'status' => 'completed',
            'remarks' => 'Students showed good understanding',
        ]);
        
        LessonPlan::create([
            'school_id' => $school->id,
            'section_id' => $primarySection->id,
            'class_id' => $grade1->id,
            'subject_id' => $mathSubject->id,
            'teacher_id' => $teachers[0]->id,
            'title' => 'Subtraction Basics',
            'content' => 'Objectives: Understand subtraction as taking away. Activities: Interactive games, visual aids, practice problems.',
            'week_number' => 2,
            'status' => 'in_progress',
            'remarks' => null,
        ]);
        
        LessonPlan::create([
            'school_id' => $school->id,
            'section_id' => $primarySection->id,
            'class_id' => $grade1->id,
            'subject_id' => $englishSubject->id,
            'teacher_id' => $teachers[0]->id,
            'title' => 'Phonics and Letter Sounds',
            'content' => 'Objectives: Master letter sounds A-E. Activities: Song, flashcards, writing practice.',
            'week_number' => 1,
            'status' => 'completed',
            'remarks' => 'Excellent participation',
        ]);
        
        $this->command->info('Lesson Plans created.');
        
        // 15. Create Syllabus entries
        Syllabus::create([
            'school_id' => $school->id,
            'section_id' => $primarySection->id,
            'class_id' => $grade1->id,
            'subject_id' => $mathSubject->id,
            'topic' => 'Numbers 1-100',
            'description' => 'Counting, reading, and writing numbers from 1 to 100',
            'status' => 'completed',
            'completion_date' => Carbon::now()->subDays(15),
        ]);
        
        Syllabus::create([
            'school_id' => $school->id,
            'section_id' => $primarySection->id,
            'class_id' => $grade1->id,
            'subject_id' => $mathSubject->id,
            'topic' => 'Basic Addition',
            'description' => 'Addition of single-digit numbers',
            'status' => 'in_progress',
            'completion_date' => null,
        ]);
        
        Syllabus::create([
            'school_id' => $school->id,
            'section_id' => $primarySection->id,
            'class_id' => $grade1->id,
            'subject_id' => $englishSubject->id,
            'topic' => 'Alphabet and Phonics',
            'description' => 'Learning all letters and their sounds',
            'status' => 'completed',
            'completion_date' => Carbon::now()->subDays(20),
        ]);
        
        $this->command->info('Syllabus entries created.');
        
        // 16. Create Timetables
        $days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];
        $subjects = Subject::where('class_id', $grade1->id)->get();
        
        foreach ($days as $dayIndex => $day) {
            foreach ($subjects as $subIndex => $subject) {
                $startHour = 8 + $subIndex;
                Timetable::create([
                    'school_id' => $school->id,
                    'class_id' => $grade1->id,
                    'section_id' => $primarySection->id,
                    'subject_id' => $subject->id,
                    'teacher_id' => $subject->teacher_id,
                    'day_of_week' => $day,
                    'start_time' => sprintf('%02d:00:00', $startHour),
                    'end_time' => sprintf('%02d:00:00', $startHour + 1),
                ]);
            }
        }
        
        // Create timetable for JSS1 as well
        $jss1Subjects = Subject::where('class_id', $jss1->id)->get();
        foreach ($days as $dayIndex => $day) {
            foreach ($jss1Subjects as $subIndex => $subject) {
                $startHour = 8 + $subIndex;
                Timetable::create([
                    'school_id' => $school->id,
                    'class_id' => $jss1->id,
                    'section_id' => $secondarySection->id,
                    'subject_id' => $subject->id,
                    'teacher_id' => $subject->teacher_id,
                    'day_of_week' => $day,
                    'start_time' => sprintf('%02d:00:00', $startHour),
                    'end_time' => sprintf('%02d:00:00', $startHour + 1),
                ]);
            }
        }
        
        $this->command->info('Timetables created.');
        
        // 17. Create Messages between users
        Message::create([
            'sender_id' => $principal->id,
            'recipient_id' => $teachers[0]->id,
            'subject' => 'Welcome to New Term',
            'body' => 'Welcome back! Looking forward to a great term ahead. Please submit your lesson plans by Friday.',
            'is_read' => true,
            'read_at' => Carbon::now()->subDays(2),
        ]);
        
        Message::create([
            'sender_id' => $teachers[0]->id,
            'recipient_id' => $principal->id,
            'subject' => 'Re: Welcome to New Term',
            'body' => 'Thank you! Lesson plans will be ready by Thursday.',
            'is_read' => false,
            'read_at' => null,
            'parent_message_id' => 1,
        ]);
        
        Message::create([
            'sender_id' => $parents[0]->id,
            'recipient_id' => $teachers[0]->id,
            'subject' => 'Question about homework',
            'body' => 'Hello, my child is having difficulty with the mathematics homework. Could you provide some guidance?',
            'is_read' => true,
            'read_at' => Carbon::now()->subHours(5),
        ]);
        
        Message::create([
            'sender_id' => $bursar->id,
            'recipient_id' => $parents[1]->id,
            'subject' => 'Fee Payment Reminder',
            'body' => 'This is a friendly reminder that the tuition fee balance is due by the end of this month.',
            'is_read' => false,
            'read_at' => null,
        ]);
        
        $this->command->info('Messages created.');
        
        // 18. Create Notifications
        Notification::create([
            'user_id' => $principal->id,
            'type' => 'system',
            'title' => 'New Term Started',
            'message' => 'The first term of 2025/2026 academic session has begun.',
            'data' => json_encode(['session_id' => $primarySession->id, 'term_id' => $activePrimaryTerm->id]),
            'is_read' => true,
            'read_at' => Carbon::now()->subDays(5),
        ]);
        
        Notification::create([
            'user_id' => $teachers[0]->id,
            'type' => 'reminder',
            'title' => 'Lesson Plan Submission Due',
            'message' => 'Please submit your lesson plans for this week.',
            'data' => json_encode(['due_date' => Carbon::now()->addDays(2)->format('Y-m-d')]),
            'is_read' => false,
            'read_at' => null,
        ]);
        
        Notification::create([
            'user_id' => $parents[0]->id,
            'type' => 'payment',
            'title' => 'Payment Received',
            'message' => 'Your payment of ₦50,000 has been received and confirmed.',
            'data' => json_encode(['amount' => 50000, 'reference' => 'REF-12345']),
            'is_read' => true,
            'read_at' => Carbon::now()->subDays(1),
        ]);
        
        Notification::create([
            'user_id' => $parents[1]->id,
            'type' => 'reminder',
            'title' => 'Outstanding Fee Balance',
            'message' => 'You have an outstanding balance of ₦30,000 for tuition fees.',
            'data' => json_encode(['amount' => 30000, 'student_id' => 2]),
            'is_read' => false,
            'read_at' => null,
        ]);
        
        foreach ($teachers as $teacher) {
            Notification::create([
                'user_id' => $teacher->id,
                'type' => 'announcement',
                'title' => 'Staff Meeting',
                'message' => 'There will be a staff meeting on Friday at 2 PM in the conference room.',
                'data' => json_encode(['date' => Carbon::now()->addDays(3)->format('Y-m-d'), 'time' => '14:00']),
                'is_read' => false,
                'read_at' => null,
            ]);
        }
        
        $this->command->info('Notifications created.');
        $this->command->info('Full School Seeding Completed Successfully.');
        $this->command->info('----------------------------------------------');
        $this->command->info('LOGIN CREDENTIALS:');
        $this->command->info('Proprietor: proprietor@apexacademy.com / password');
        $this->command->info('Principal: principal@apexacademy.com / password');
        $this->command->info('Bursar: bursar@apexacademy.com / password');
        $this->command->info('Teacher: teacher1@apexacademy.com / password');
        $this->command->info('Parent: parent1@apexacademy.com / password');
    }
    
    /**
     * Calculate grade based on score
     */
    private function calculateGrade($score)
    {
        if ($score >= 90) return 'A';
        if ($score >= 80) return 'B';
        if ($score >= 70) return 'C';
        if ($score >= 60) return 'D';
        if ($score >= 50) return 'E';
        return 'F';
    }
}
