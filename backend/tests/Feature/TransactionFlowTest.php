<?php

namespace Tests\Feature;

use App\Models\AcademicSession;
use App\Models\ClassModel;
use App\Models\School;
use App\Models\Section;
use App\Models\Student;
use App\Models\Term;
use App\Models\Transaction;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TransactionFlowTest extends TestCase
{
    use RefreshDatabase;

    protected $user;

    protected $school;

    protected $section;

    protected $session;

    protected $term;

    protected $class;

    protected $student;

    protected function setUp(): void
    {
        parent::setUp();

        $this->school = School::factory()->create(['name' => 'Test School']);

        $this->user = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'proprietor',
        ]);

        $this->section = Section::create([
            'school_id' => $this->school->id,
            'section_name' => 'Primary',
        ]);

        $this->session = AcademicSession::create([
            'school_id' => $this->school->id,
            'session_name' => '2023/2024',
            'section_id' => $this->section->id,
            'start_date' => now(),
            'end_date' => now()->addYear(),
        ]);

        $this->term = Term::create([
            'school_id' => $this->school->id,
            'term_name' => 'First Term',
            'session_id' => $this->session->id,
            'section_id' => $this->section->id,
            'start_date' => now(),
            'end_date' => now()->addMonths(3),
        ]);

        $this->class = ClassModel::create([
            'school_id' => $this->school->id,
            'class_name' => 'Basic 1',
            'section_id' => $this->section->id,
        ]);

        $this->student = Student::create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_id' => $this->class->id,
            'student_name' => 'John Doe',
            'admission_number' => 'ADM001',
        ]);
    }

    public function test_can_create_income_transaction()
    {
        $response = $this->actingAs($this->user, 'api')->postJson("/api/schools/{$this->school->id}/transactions", [
            'section_id' => $this->section->id,
            'session_id' => $this->session->id,
            'term_id' => $this->term->id,
            'student_id' => $this->student->id,
            'transaction_type' => 'income',
            'amount' => 5000,
            'payment_method' => 'cash',
            'category' => 'School Fees',
            'description' => 'Manual payment for first term',
            'transaction_date' => now()->toDateString(),
        ]);

        $response->assertStatus(201)
            ->assertJsonFragment(['transaction_type' => 'income', 'amount' => '5000.00']);

        $this->assertDatabaseHas('transactions', [
            'transaction_type' => 'income',
            'amount' => 5000,
            'category' => 'School Fees',
        ]);
    }

    public function test_can_create_expense_transaction()
    {
        $response = $this->actingAs($this->user, 'api')->postJson("/api/schools/{$this->school->id}/transactions", [
            'section_id' => $this->section->id,
            'session_id' => $this->session->id,
            'term_id' => $this->term->id,
            'transaction_type' => 'expense',
            'amount' => 2000,
            'payment_method' => 'cash',
            'category' => 'Stationary',
            'description' => 'Buying chalks',
            'transaction_date' => now()->toDateString(),
        ]);

        $response->assertStatus(201)
            ->assertJsonFragment(['transaction_type' => 'expense', 'amount' => '2000.00']);

        $this->assertDatabaseHas('transactions', [
            'transaction_type' => 'expense',
            'amount' => 2000,
            'category' => 'Stationary',
        ]);
    }

    public function test_can_get_dashboard_stats()
    {
        // Create some transactions
        Transaction::create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'transaction_type' => 'income',
            'amount' => 10000,
            'payment_method' => 'cash',
            'transaction_date' => now()->toDateString(),
            'recorded_by' => $this->user->id,
        ]);

        Transaction::create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'transaction_type' => 'expense',
            'amount' => 4000,
            'payment_method' => 'cash',
            'transaction_date' => now()->toDateString(),
            'recorded_by' => $this->user->id,
        ]);

        $response = $this->actingAs($this->user, 'api')->getJson("/api/schools/{$this->school->id}/transactions-dashboard-stats");

        $response->assertStatus(200)
            ->assertJsonFragment(['total_income' => 10000, 'total_expenses' => 4000, 'balance' => 6000]);
    }

    public function test_can_get_transaction_report()
    {
        Transaction::create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'transaction_type' => 'income',
            'amount' => 5000,
            'payment_method' => 'cash',
            'transaction_date' => now()->toDateString(),
            'recorded_by' => $this->user->id,
        ]);

        $response = $this->actingAs($this->user, 'api')->getJson("/api/schools/{$this->school->id}/transactions-report?start_date=".now()->subDay()->toDateString().'&end_date='.now()->addDay()->toDateString());

        $response->assertStatus(200)
            ->assertJsonStructure([
                'success',
                'data' => [
                    'total_income',
                    'total_expenses',
                    'net_balance',
                    'transactions',
                ],
            ]);
    }
}
