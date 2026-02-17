<?php

namespace App\Console\Commands;

use App\Models\AcademicSession;
use App\Models\ClassModel;
use App\Models\Fee;
use App\Models\School;
use App\Models\Section;
use App\Models\Student;
use App\Models\Term;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class ImportFirestoreData extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'import:firestore {path=../migration-scripts/firestore-export}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Import data from Firestore JSON exports to MySQL';

    /**
     * ID mapping for Firestore to MySQL
     */
    protected $idMap = [
        'schools' => [],
        'users' => [],
        'sections' => [],
        'sessions' => [],
        'terms' => [],
        'classes' => [],
        'students' => [],
        'fees' => [],
        'transactions' => [],
    ];

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $path = $this->argument('path');

        if (! is_dir($path)) {
            $this->error("Directory not found: {$path}");

            return 1;
        }

        $this->info('🚀 Starting Firestore data import...');
        $this->newLine();

        DB::beginTransaction();

        try {
            // Import in order of dependencies
            $this->importSchools($path);
            $this->importSections($path);
            $this->importUsers($path);
            $this->importAcademicSessions($path);
            $this->importTerms($path);
            $this->importClasses($path);
            $this->importStudents($path);
            $this->importFees($path);
            $this->importTransactions($path);

            DB::commit();

            $this->newLine();
            $this->info('✅ Import completed successfully!');
            $this->displaySummary();

            return 0;
        } catch (\Exception $e) {
            DB::rollBack();
            $this->error('❌ Import failed: '.$e->getMessage());
            $this->error($e->getTraceAsString());

            return 1;
        }
    }

    /**
     * Import schools
     */
    protected function importSchools($path)
    {
        $this->info('Importing schools...');
        $data = $this->readJsonFile($path, 'schools.json');

        foreach ($data as $item) {
            $school = School::create([
                'name' => $item['name'] ?? 'Unnamed School',
                'address' => $item['address'] ?? null,
                'phone' => $item['phone'] ?? null,
                'email' => $item['email'] ?? null,
                'logo_url' => $item['logoUrl'] ?? null,
                'is_active' => $item['isActive'] ?? true,
                'created_at' => $item['createdAt'] ?? now(),
                'updated_at' => $item['updatedAt'] ?? now(),
            ]);

            $this->idMap['schools'][$item['id']] = $school->id;
        }

        $this->info('✅ Imported '.count($data).' schools');
    }

    /**
     * Import sections
     */
    protected function importSections($path)
    {
        $this->info('Importing sections...');
        $data = $this->readJsonFile($path, 'sections.json');

        foreach ($data as $item) {
            $schoolId = $this->idMap['schools'][$item['schoolId']] ?? null;

            if (! $schoolId) {
                $this->warn("Skipping section {$item['id']}: school not found");

                continue;
            }

            $section = Section::create([
                'school_id' => $schoolId,
                'section_name' => $item['sectionName'] ?? $item['name'] ?? 'Unnamed Section',
                'description' => $item['description'] ?? null,
                'is_active' => $item['isActive'] ?? true,
                'created_at' => $item['createdAt'] ?? now(),
                'updated_at' => $item['updatedAt'] ?? now(),
            ]);

            $this->idMap['sections'][$item['id']] = $section->id;
        }

        $this->info('✅ Imported '.count($data).' sections');
    }

    /**
     * Import users
     */
    protected function importUsers($path)
    {
        $this->info('Importing users...');
        $data = $this->readJsonFile($path, 'users.json');

        foreach ($data as $item) {
            $schoolId = $this->idMap['schools'][$item['schoolId']] ?? null;

            if (! $schoolId) {
                $this->warn("Skipping user {$item['id']}: school not found");

                continue;
            }

            $user = User::create([
                'firebase_uid' => $item['id'],
                'school_id' => $schoolId,
                'email' => $item['email'] ?? 'user_'.$item['id'].'@example.com',
                'password' => Hash::make('password'), // Default password
                'full_name' => $item['fullName'] ?? $item['name'] ?? 'Unknown User',
                'role' => strtolower($item['role'] ?? 'teacher'),
                'is_active' => $item['isActive'] ?? true,
                'email_verified_at' => isset($item['emailVerified']) && $item['emailVerified'] ? now() : null,
                'created_at' => $item['createdAt'] ?? now(),
                'updated_at' => $item['updatedAt'] ?? now(),
            ]);

            $this->idMap['users'][$item['id']] = $user->id;

            // Assign sections if available
            if (isset($item['sections']) && is_array($item['sections'])) {
                $sectionIds = [];
                foreach ($item['sections'] as $firestoreSectionId) {
                    if (isset($this->idMap['sections'][$firestoreSectionId])) {
                        $sectionIds[] = $this->idMap['sections'][$firestoreSectionId];
                    }
                }
                if (! empty($sectionIds)) {
                    $user->sections()->sync($sectionIds);
                }
            }
        }

        $this->info('✅ Imported '.count($data).' users');
    }

    /**
     * Import academic sessions
     */
    protected function importAcademicSessions($path)
    {
        $this->info('Importing academic sessions...');
        $data = $this->readJsonFile($path, 'academicSessions.json');

        foreach ($data as $item) {
            $schoolId = $this->idMap['schools'][$item['schoolId']] ?? null;
            $sectionId = $this->idMap['sections'][$item['sectionId']] ?? null;

            if (! $schoolId || ! $sectionId) {
                $this->warn("Skipping session {$item['id']}: school or section not found");

                continue;
            }

            $session = AcademicSession::create([
                'school_id' => $schoolId,
                'section_id' => $sectionId,
                'session_name' => $item['sessionName'] ?? $item['name'] ?? 'Unnamed Session',
                'start_date' => $item['startDate'] ?? now(),
                'end_date' => $item['endDate'] ?? now()->addYear(),
                'is_active' => $item['isActive'] ?? true,
                'created_at' => $item['createdAt'] ?? now(),
                'updated_at' => $item['updatedAt'] ?? now(),
            ]);

            $this->idMap['sessions'][$item['id']] = $session->id;
        }

        $this->info('✅ Imported '.count($data).' academic sessions');
    }

    /**
     * Import terms
     */
    protected function importTerms($path)
    {
        $this->info('Importing terms...');
        $data = $this->readJsonFile($path, 'terms.json');

        foreach ($data as $item) {
            $schoolId = $this->idMap['schools'][$item['schoolId']] ?? null;
            $sectionId = $this->idMap['sections'][$item['sectionId']] ?? null;
            $sessionId = $this->idMap['sessions'][$item['sessionId']] ?? null;

            if (! $schoolId || ! $sectionId || ! $sessionId) {
                $this->warn("Skipping term {$item['id']}: dependencies not found");

                continue;
            }

            $term = Term::create([
                'school_id' => $schoolId,
                'section_id' => $sectionId,
                'session_id' => $sessionId,
                'term_name' => $item['termName'] ?? $item['name'] ?? 'Unnamed Term',
                'start_date' => $item['startDate'] ?? now(),
                'end_date' => $item['endDate'] ?? now()->addMonths(3),
                'is_active' => $item['isActive'] ?? true,
                'created_at' => $item['createdAt'] ?? now(),
                'updated_at' => $item['updatedAt'] ?? now(),
            ]);

            $this->idMap['terms'][$item['id']] = $term->id;
        }

        $this->info('✅ Imported '.count($data).' terms');
    }

    /**
     * Import classes
     */
    protected function importClasses($path)
    {
        $this->info('Importing classes...');
        $data = $this->readJsonFile($path, 'classes.json');

        foreach ($data as $item) {
            $schoolId = $this->idMap['schools'][$item['schoolId']] ?? null;
            $sectionId = $this->idMap['sections'][$item['sectionId']] ?? null;

            if (! $schoolId || ! $sectionId) {
                $this->warn("Skipping class {$item['id']}: school or section not found");

                continue;
            }

            $class = ClassModel::create([
                'school_id' => $schoolId,
                'section_id' => $sectionId,
                'class_name' => $item['className'] ?? $item['name'] ?? 'Unnamed Class',
                'description' => $item['description'] ?? null,
                'created_at' => $item['createdAt'] ?? now(),
                'updated_at' => $item['updatedAt'] ?? now(),
            ]);

            $this->idMap['classes'][$item['id']] = $class->id;
        }

        $this->info('✅ Imported '.count($data).' classes');
    }

    /**
     * Import students
     */
    protected function importStudents($path)
    {
        $this->info('Importing students...');
        $data = $this->readJsonFile($path, 'students.json');

        foreach ($data as $item) {
            $schoolId = $this->idMap['schools'][$item['schoolId']] ?? null;
            $sectionId = $this->idMap['sections'][$item['sectionId']] ?? null;
            $classId = $this->idMap['classes'][$item['classId']] ?? null;

            if (! $schoolId || ! $sectionId || ! $classId) {
                $this->warn("Skipping student {$item['id']}: dependencies not found");

                continue;
            }

            $student = Student::create([
                'school_id' => $schoolId,
                'section_id' => $sectionId,
                'class_id' => $classId,
                'student_name' => $item['studentName'] ?? $item['name'] ?? 'Unnamed Student',
                'admission_number' => $item['admissionNumber'] ?? null,
                'date_of_birth' => $item['dateOfBirth'] ?? null,
                'gender' => isset($item['gender']) ? strtolower($item['gender']) : null,
                'address' => $item['address'] ?? null,
                'parent_name' => $item['parentName'] ?? null,
                'parent_phone' => $item['parentPhone'] ?? null,
                'parent_email' => $item['parentEmail'] ?? null,
                'photo_url' => $item['photoUrl'] ?? null,
                'is_active' => $item['isActive'] ?? true,
                'created_at' => $item['createdAt'] ?? now(),
                'updated_at' => $item['updatedAt'] ?? now(),
            ]);

            $this->idMap['students'][$item['id']] = $student->id;
        }

        $this->info('✅ Imported '.count($data).' students');
    }

    /**
     * Import fees
     */
    protected function importFees($path)
    {
        $this->info('Importing fees...');
        $data = $this->readJsonFile($path, 'fees.json');

        foreach ($data as $item) {
            $schoolId = $this->idMap['schools'][$item['schoolId']] ?? null;
            $sectionId = $this->idMap['sections'][$item['sectionId']] ?? null;
            $sessionId = $this->idMap['sessions'][$item['sessionId']] ?? null;
            $termId = $this->idMap['terms'][$item['termId']] ?? null;

            if (! $schoolId || ! $sectionId || ! $sessionId || ! $termId) {
                $this->warn("Skipping fee {$item['id']}: dependencies not found");

                continue;
            }

            $classId = isset($item['classId']) ? ($this->idMap['classes'][$item['classId']] ?? null) : null;

            $fee = Fee::create([
                'school_id' => $schoolId,
                'section_id' => $sectionId,
                'session_id' => $sessionId,
                'term_id' => $termId,
                'class_id' => $classId,
                'fee_name' => $item['feeName'] ?? $item['name'] ?? 'Unnamed Fee',
                'amount' => $item['amount'] ?? 0,
                'fee_scope' => $item['feeScope'] ?? 'section',
                'description' => $item['description'] ?? null,
                'is_active' => $item['isActive'] ?? true,
                'created_at' => $item['createdAt'] ?? now(),
                'updated_at' => $item['updatedAt'] ?? now(),
            ]);

            $this->idMap['fees'][$item['id']] = $fee->id;
        }

        $this->info('✅ Imported '.count($data).' fees');
    }

    /**
     * Import transactions
     */
    protected function importTransactions($path)
    {
        $this->info('Importing transactions...');
        $data = $this->readJsonFile($path, 'transactions.json');

        foreach ($data as $item) {
            $schoolId = $this->idMap['schools'][$item['schoolId']] ?? null;
            $sectionId = $this->idMap['sections'][$item['sectionId']] ?? null;
            $recordedBy = $this->idMap['users'][$item['recordedBy']] ?? 1;

            if (! $schoolId || ! $sectionId) {
                $this->warn("Skipping transaction {$item['id']}: dependencies not found");

                continue;
            }

            $sessionId = isset($item['sessionId']) ? ($this->idMap['sessions'][$item['sessionId']] ?? null) : null;
            $termId = isset($item['termId']) ? ($this->idMap['terms'][$item['termId']] ?? null) : null;
            $studentId = isset($item['studentId']) ? ($this->idMap['students'][$item['studentId']] ?? null) : null;

            $transaction = Transaction::create([
                'school_id' => $schoolId,
                'section_id' => $sectionId,
                'session_id' => $sessionId,
                'term_id' => $termId,
                'student_id' => $studentId,
                'transaction_type' => strtolower($item['transactionType'] ?? $item['type'] ?? 'income'),
                'amount' => $item['amount'] ?? 0,
                'payment_method' => strtolower(str_replace(' ', '_', $item['paymentMethod'] ?? 'cash')),
                'category' => $item['category'] ?? null,
                'description' => $item['description'] ?? null,
                'reference_number' => $item['referenceNumber'] ?? null,
                'transaction_date' => $item['transactionDate'] ?? $item['date'] ?? now(),
                'recorded_by' => $recordedBy,
                'created_at' => $item['createdAt'] ?? now(),
                'updated_at' => $item['updatedAt'] ?? now(),
            ]);

            $this->idMap['transactions'][$item['id']] = $transaction->id;
        }

        $this->info('✅ Imported '.count($data).' transactions');
    }

    /**
     * Read JSON file
     */
    protected function readJsonFile($path, $filename)
    {
        $filepath = $path.'/'.$filename;

        if (! file_exists($filepath)) {
            $this->warn("File not found: {$filename}, skipping...");

            return [];
        }

        $content = file_get_contents($filepath);

        return json_decode($content, true) ?? [];
    }

    /**
     * Display import summary
     */
    protected function displaySummary()
    {
        $this->info('📊 Import Summary:');
        $this->info(str_repeat('─', 40));

        foreach ($this->idMap as $type => $map) {
            $count = count($map);
            $this->info(str_pad($type, 20)." {$count} records");
        }

        $this->info(str_repeat('─', 40));
        $total = array_sum(array_map('count', $this->idMap));
        $this->info("Total: {$total} records");
    }
}
