<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Fee;
use App\Models\Payment;
use App\Models\Transaction;
use App\Models\Student;
use App\Models\ExamResult;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    /**
     * Get monthly financial summary
     */
    public function financialSummary(Request $request)
    {
        $year = $request->input('year', date('Y'));

        $monthlyPayments = Payment::whereYear('created_at', $year)
            ->where('status', 'success')
            ->select(DB::raw('MONTH(created_at) as month'), DB::raw('SUM(amount) as total'))
            ->groupBy('month')
            ->get();

        $monthlyManualIncome = Transaction::whereYear('transaction_date', $year)
            ->where('transaction_type', 'income')
            ->select(DB::raw('MONTH(transaction_date) as month'), DB::raw('SUM(amount) as total'))
            ->groupBy('month')
            ->get();

        $monthlyManualExpense = Transaction::whereYear('transaction_date', $year)
            ->where('transaction_type', 'expense')
            ->select(DB::raw('MONTH(transaction_date) as month'), DB::raw('SUM(amount) as total'))
            ->groupBy('month')
            ->get();

        $data = [];
        for ($i = 1; $i <= 12; $i++) {
            $paymentTotal = $monthlyPayments->firstWhere('month', $i)->total ?? 0;
            $manualIncomeTotal = $monthlyManualIncome->firstWhere('month', $i)->total ?? 0;
            $manualExpenseTotal = $monthlyManualExpense->firstWhere('month', $i)->total ?? 0;

            $data[] = [
                'month' => date('M', mktime(0, 0, 0, $i, 1)),
                'income' => (float) $paymentTotal + (float) $manualIncomeTotal,
                'expenses' => (float) $manualExpenseTotal,
            ];
        }

        return response()->json(['success' => true, 'data' => $data]);
    }

    /**
     * Get payment method distribution
     */
    public function paymentMethods(Request $request)
    {
        $distribution = Payment::select(
            'payment_method',
            DB::raw('COUNT(*) as count'),
            DB::raw('SUM(amount) as total')
        )
            ->where('status', 'success')
            ->groupBy('payment_method')
            ->get();

        return response()->json(['success' => true, 'data' => $distribution]);
    }

    /**
     * Get fee collection status
     */
    public function feeCollection(Request $request)
    {
        $paymentCollected = Payment::where('status', 'success')->sum('amount');
        $manualCollected = Transaction::where('transaction_type', 'income')
            ->where('category', 'like', '%School Fee%')
            ->sum('amount');

        $totalCollected = (float) $paymentCollected + (float) $manualCollected;

        $schoolFeesTotal = Fee::where('fee_scope', 'school')->where('is_active', true)->sum('amount');
        $activeStudentsCount = Student::where('is_active', true)->count();
        $expectedFromSchoolFees = $schoolFeesTotal * $activeStudentsCount;

        $expectedFromSectionFees = DB::table('fees')
            ->join('students', 'fees.section_id', '=', 'students.section_id')
            ->where('fees.fee_scope', 'section')
            ->where('fees.is_active', true)
            ->where('students.is_active', true)
            ->sum('fees.amount');

        $expectedFromClassFees = DB::table('fees')
            ->join('students', 'fees.class_id', '=', 'students.class_id')
            ->where('fees.fee_scope', 'class')
            ->where('fees.is_active', true)
            ->where('students.is_active', true)
            ->sum('fees.amount');

        $totalExpected = (float) $expectedFromSchoolFees + (float) $expectedFromSectionFees + (float) $expectedFromClassFees;

        return response()->json([
            'success' => true,
            'data' => [
                'collected' => $totalCollected,
                'outstanding' => max(0, $totalExpected - $totalCollected),
                'expected' => $totalExpected,
            ]
        ]);
    }

    /**
     * Get list of students with outstanding balances
     */
    public function debtors(Request $request)
    {
        $schoolId = $request->route('school') ?? $request->input('school_id');
        $sectionId = $request->input('section_id');

        if (!$schoolId) {
            return response()->json(['success' => false, 'message' => 'School ID required'], 400);
        }

        $students = Student::where('school_id', $schoolId)
            ->where('is_active', true)
            ->when($sectionId, function ($q) use ($sectionId) {
                return $q->where('section_id', $sectionId);
            })
            ->with(['section', 'classModel'])
            ->get();

        $debtors = [];

        foreach ($students as $student) {
            $totalFees = Fee::where('school_id', $schoolId)
                ->where('is_active', true)
                ->where(function ($q) use ($student) {
                    $q->where('fee_scope', 'school')
                      ->orWhere(fn($sq) => $sq->where('fee_scope', 'section')->where('section_id', $student->section_id))
                      ->orWhere(fn($sq) => $sq->where('fee_scope', 'class')->where('class_id', $student->class_id))
                      ->orWhere(fn($sq) => $sq->where('fee_scope', 'student')->where('student_id', $student->id));
                })
                ->sum('amount');

            $manualPaid = Transaction::where('student_id', $student->id)
                ->where('transaction_type', 'income')
                ->where('category', 'like', '%Fee%')
                ->sum('amount');

            $autoPaid = Payment::where('student_id', $student->id)
                ->where('status', 'success')
                ->sum('amount');

            $totalPaid = (float) $manualPaid + (float) $autoPaid;
            $balance = (float) $totalFees - $totalPaid;

            if ($balance > 0) {
                $debtors[] = [
                    'student_id' => $student->id,
                    'student_name' => $student->student_name,
                    'section_name' => $student->section->section_name ?? 'N/A',
                    'class_name' => $student->classModel->class_name ?? 'N/A',
                    'parent_name' => $student->parent_name,
                    'parent_phone' => $student->parent_phone,
                    'balance' => $balance,
                ];
            }
        }

        return response()->json(['success' => true, 'data' => $debtors]);
    }

    /**
     * Get academic report card for a student
     */
    public function academicReportCard(Request $request, $studentId)
    {
        $termId = $request->input('term_id');
        $sessionId = $request->input('session_id');

        $query = ExamResult::with(['exam.subject', 'exam.term', 'exam.session'])
            ->where('student_id', $studentId);

        if ($termId) $query->whereHas('exam', fn($q) => $q->where('term_id', $termId));
        if ($sessionId) $query->whereHas('exam', fn($q) => $q->where('session_id', $sessionId));

        $results = $query->get();

        $student = Student::with(['classModel', 'section'])->find($studentId);

        return response()->json([
            'success' => true,
            'data' => [
                'student' => $student,
                'results' => $results
            ]
        ]);
    }
}
