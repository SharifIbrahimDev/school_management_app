<?php

namespace Tests\Feature;

use App\Models\AcademicSession;
use App\Models\ClassModel;
use App\Models\Fee;
use App\Models\Payment;
use App\Models\School;
use App\Models\Section;
use App\Models\Student;
use App\Models\Term;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class FeeFlowTest extends TestCase
{
    use RefreshDatabase;

    protected $school;

    protected $user;

    protected $student;

    protected $fee;

    protected $session;

    protected $term;

    protected $section;

    protected $class;

    protected function setUp(): void
    {
        parent::setUp();

        $this->school = School::factory()->create([
            'name' => 'Fee Test School',
        ]);

        $this->user = User::factory()->create([
            'school_id' => $this->school->id,
            'role' => 'proprietor',
        ]);

        // Create Section first
        $this->section = Section::create([
            'school_id' => $this->school->id,
            'section_name' => 'A',
        ]);

        $this->session = AcademicSession::create([
            'school_id' => $this->school->id,
            'session_name' => '2024/2025',
            'start_date' => now(),
            'end_date' => now()->addYear(),
            'section_id' => $this->section->id,
        ]);

        $this->term = Term::create([
            'school_id' => $this->school->id,
            'term_name' => 'First Term',
            'session_id' => $this->session->id,
            'section_id' => $this->section->id,
            'start_date' => now(),
            'end_date' => now()->addMonths(3),
        ]);

        // Section created above

        $this->class = ClassModel::create([
            'school_id' => $this->school->id,
            'section_id' => $this->section->id,
            'class_name' => 'SS 1',
        ]);

        $this->student = Student::create([
            'school_id' => $this->school->id,
            'student_name' => 'Jane Student',
            'admission_number' => 'FEE/001',
            'class_id' => $this->class->id,
            'section_id' => $this->section->id,
        ]);
    }

    public function test_can_create_fee_structure()
    {
        $response = $this->actingAs($this->user, 'api')->postJson("/api/schools/{$this->school->id}/fees", [
            'fee_name' => 'Tuition Fee 1st Term',
            'amount' => 50000,
            'fee_scope' => 'class',
            'class_id' => $this->class->id,
            'session_id' => $this->session->id,
            'term_id' => $this->term->id,
            'section_id' => $this->section->id,
        ]);

        $response->assertStatus(201)
            ->assertJsonFragment(['fee_name' => 'Tuition Fee 1st Term']);

        $this->assertDatabaseHas('fees', ['fee_name' => 'Tuition Fee 1st Term', 'amount' => 50000]);

        return $response->json('data.id');
    }

    public function test_can_initialize_payment()
    {
        // 1. Create a fee manually
        $fee = Fee::create([
            'school_id' => $this->school->id,
            'fee_name' => 'Bus Fee',
            'amount' => 10000,
            'fee_scope' => 'school',
            'session_id' => $this->session->id,
            'term_id' => $this->term->id,
            'section_id' => $this->section->id,
        ]);

        // Mock Paystack
        Http::fake([
            'https://api.paystack.co/transaction/initialize' => Http::response([
                'status' => true,
                'data' => [
                    'authorization_url' => 'https://checkout.paystack.com/access_code',
                    'access_code' => 'access_code_123',
                    'reference' => 'ref_12345',
                ],
            ], 200),
        ]);

        $response = $this->actingAs($this->user, 'api')->postJson('/api/payments/initialize', [
            'email' => 'tunde@example.com',
            'amount' => 10000,
            'student_id' => $this->student->id,
            'fee_id' => $fee->id,
        ]);

        $response->assertStatus(200)
            ->assertJsonFragment(['access_code' => 'access_code_123']);

        $this->assertDatabaseHas('payments', [
            'student_id' => $this->student->id,
            'amount' => 10000,
            'status' => 'pending',
        ]);
    }

    public function test_can_verify_payment()
    {
        $fee = Fee::create([
            'school_id' => $this->school->id,
            'fee_name' => 'Exam Fee',
            'amount' => 5000,
            'fee_scope' => 'class',
            'class_id' => $this->class->id,
            'session_id' => $this->session->id,
            'term_id' => $this->term->id,
            'section_id' => $this->section->id,
        ]);

        $reference = 'PAY_TEST_'.time();

        // Create pending payment
        Payment::create([
            'student_id' => $this->student->id,
            'fee_id' => $fee->id,
            'amount' => 5000,
            'payment_method' => 'paystack',
            'reference' => $reference,
            'status' => 'pending',
            'paid_at' => null,
        ]);

        // Mock Paystack Verify
        Http::fake([
            "https://api.paystack.co/transaction/verify/{$reference}" => Http::response([
                'status' => true,
                'data' => [
                    'status' => 'success',
                    'reference' => $reference,
                    'amount' => 500000, // kobo
                    'channel' => 'card',
                    'gateway_response' => 'Successful',
                    'metadata' => [
                        'student_id' => $this->student->id,
                        'fee_id' => $fee->id,
                    ],
                ],
            ], 200),
        ]);

        $response = $this->actingAs($this->user, 'api')->postJson('/api/payments/verify', [
            'reference' => $reference,
        ]);

        $response->assertStatus(200);

        $this->assertDatabaseHas('payments', [
            'reference' => $reference,
            'status' => 'success',
        ]);
    }
}
