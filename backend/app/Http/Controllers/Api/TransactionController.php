<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class TransactionController extends Controller
{
    /**
     * Display transactions for a school
     */
    public function index(Request $request, string $schoolId): JsonResponse
    {
        $transactions = Transaction::where('school_id', $schoolId)
            ->with(['section', 'academicSession', 'term', 'student', 'recorder'])
            ->when($request->has('section_id'), function ($query) use ($request) {
                $query->where('section_id', $request->section_id);
            })
            ->when($request->has('session_id'), function ($query) use ($request) {
                $query->where('session_id', $request->session_id);
            })
            ->when($request->has('term_id'), function ($query) use ($request) {
                $query->where('term_id', $request->term_id);
            })
            ->when($request->has('student_id'), function ($query) use ($request) {
                $query->where('student_id', $request->student_id);
            })
            ->when($request->has('transaction_type'), function ($query) use ($request) {
                $query->where('transaction_type', $request->transaction_type);
            })
            ->when($request->has('payment_method'), function ($query) use ($request) {
                $query->where('payment_method', $request->payment_method);
            })
            ->when($request->has('start_date'), function ($query) use ($request) {
                $query->where('transaction_date', '>=', $request->start_date);
            })
            ->when($request->has('end_date'), function ($query) use ($request) {
                $query->where('transaction_date', '<=', $request->end_date);
            })
            ->when($request->has('search'), function ($query) use ($request) {
                $query->where(function ($q) use ($request) {
                    $q->where('reference_number', 'like', '%'.$request->search.'%')
                        ->orWhere('description', 'like', '%'.$request->search.'%')
                        ->orWhere('category', 'like', '%'.$request->search.'%');
                });
            })
            ->orderBy('transaction_date', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json([
            'success' => true,
            'data' => $transactions,
        ]);
    }

    /**
     * Store a newly created transaction
     */
    public function store(Request $request, string $schoolId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'required|exists:sections,id',
            'session_id' => 'nullable|exists:academic_sessions,id',
            'term_id' => 'nullable|exists:terms,id',
            'student_id' => 'nullable|exists:students,id',
            'transaction_type' => 'required|in:income,expense',
            'amount' => 'required|numeric|min:0',
            'payment_method' => 'required|in:cash,bank_transfer,cheque,mobile_money',
            'category' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'reference_number' => 'nullable|string|max:100',
            'transaction_date' => 'required|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        // Get authenticated user ID (will be from JWT token)
        $recordedBy = $request->user() ? $request->user()->id : 1; // Default to 1 for now

        $transaction = Transaction::create([
            'school_id' => $schoolId,
            'section_id' => $request->section_id,
            'session_id' => $request->session_id,
            'term_id' => $request->term_id,
            'student_id' => $request->student_id,
            'transaction_type' => $request->transaction_type,
            'amount' => $request->amount,
            'payment_method' => $request->payment_method,
            'category' => $request->category,
            'description' => $request->description,
            'reference_number' => $request->reference_number,
            'transaction_date' => $request->transaction_date,
            'recorded_by' => $recordedBy,
        ]);

        // Trigger notification for payment (income) if linked to a student with a parent
        if ($transaction->transaction_type === 'income' && $transaction->student_id) {
            $student = $transaction->student;
            if ($student && $student->parent_id) {
                \App\Models\Notification::create([
                    'user_id' => $student->parent_id,
                    'type' => 'payment_received',
                    'title' => 'Payment Received',
                    'message' => "A payment of {$transaction->amount} has been received for {$student->student_name}.",
                    'data' => [
                        'transaction_id' => $transaction->id,
                        'student_id' => $student->id,
                        'amount' => $transaction->amount,
                    ],
                ]);
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'Transaction recorded successfully',
            'data' => $transaction->load(['section', 'student', 'recorder']),
        ], 201);
    }

    /**
     * Display the specified transaction
     */
    public function show(string $schoolId, string $id): JsonResponse
    {
        $transaction = Transaction::where('school_id', $schoolId)
            ->with(['section', 'academicSession', 'term', 'student', 'recorder'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $transaction,
        ]);
    }

    /**
     * Update the specified transaction
     */
    public function update(Request $request, string $schoolId, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'sometimes|required|exists:sections,id',
            'session_id' => 'nullable|exists:academic_sessions,id',
            'term_id' => 'nullable|exists:terms,id',
            'student_id' => 'nullable|exists:students,id',
            'transaction_type' => 'sometimes|required|in:income,expense',
            'amount' => 'sometimes|required|numeric|min:0',
            'payment_method' => 'sometimes|required|in:cash,bank_transfer,cheque,mobile_money',
            'category' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'reference_number' => 'nullable|string|max:100',
            'transaction_date' => 'sometimes|required|date',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $transaction = Transaction::where('school_id', $schoolId)->findOrFail($id);
        $transaction->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Transaction updated successfully',
            'data' => $transaction->load(['section', 'student', 'recorder']),
        ]);
    }

    /**
     * Remove the specified transaction
     */
    public function destroy(string $schoolId, string $id): JsonResponse
    {
        $transaction = Transaction::where('school_id', $schoolId)->findOrFail($id);
        $transaction->delete();

        return response()->json([
            'success' => true,
            'message' => 'Transaction deleted successfully',
        ]);
    }

    /**
     * Get dashboard statistics
     */
    public function dashboardStats(Request $request, string $schoolId): JsonResponse
    {
        $query = Transaction::where('school_id', $schoolId);

        // Apply filters
        if ($request->has('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        if ($request->has('session_id')) {
            $query->where('session_id', $request->session_id);
        }

        if ($request->has('term_id')) {
            $query->where('term_id', $request->term_id);
        }

        if ($request->has('start_date')) {
            $query->where('transaction_date', '>=', $request->start_date);
        }

        if ($request->has('end_date')) {
            $query->where('transaction_date', '<=', $request->end_date);
        }

        // Calculate statistics
        $totalIncome = (clone $query)->where('transaction_type', 'income')->sum('amount');
        $totalExpenses = (clone $query)->where('transaction_type', 'expense')->sum('amount');
        $balance = $totalIncome - $totalExpenses;

        $stats = [
            'total_income' => $totalIncome,
            'total_expenses' => $totalExpenses,
            'balance' => $balance,
            'cash_in_hand' => (clone $query)->where('payment_method', 'cash')->sum('amount'),
            'bank_balance' => (clone $query)->where('payment_method', 'bank_transfer')->sum('amount'),
            'income_count' => (clone $query)->where('transaction_type', 'income')->count(),
            'expense_count' => (clone $query)->where('transaction_type', 'expense')->count(),
            'income_by_method' => (clone $query)
                ->where('transaction_type', 'income')
                ->select('payment_method', DB::raw('SUM(amount) as total'))
                ->groupBy('payment_method')
                ->get(),
            'expense_by_category' => (clone $query)
                ->where('transaction_type', 'expense')
                ->select('category', DB::raw('SUM(amount) as total'))
                ->groupBy('category')
                ->get(),
            'recent_transactions' => (clone $query)
                ->with(['student', 'recorder'])
                ->orderBy('transaction_date', 'desc')
                ->limit(10)
                ->get(),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats,
        ]);
    }

    /**
     * Generate transaction report
     */
    public function report(Request $request, string $schoolId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'start_date' => 'required|date',
            'end_date' => 'required|date|after_or_equal:start_date',
            'section_id' => 'nullable|exists:sections,id',
            'transaction_type' => 'nullable|in:income,expense',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $query = Transaction::where('school_id', $schoolId)
            ->whereBetween('transaction_date', [$request->start_date, $request->end_date]);

        if ($request->has('section_id')) {
            $query->where('section_id', $request->section_id);
        }

        if ($request->has('transaction_type')) {
            $query->where('transaction_type', $request->transaction_type);
        }

        $transactions = $query->with(['section', 'student', 'recorder'])
            ->orderBy('transaction_date', 'asc')
            ->get();

        $summary = [
            'period' => [
                'start_date' => $request->start_date,
                'end_date' => $request->end_date,
            ],
            'total_income' => $transactions->where('transaction_type', 'income')->sum('amount'),
            'total_expenses' => $transactions->where('transaction_type', 'expense')->sum('amount'),
            'net_balance' => $transactions->where('transaction_type', 'income')->sum('amount') -
                           $transactions->where('transaction_type', 'expense')->sum('amount'),
            'transaction_count' => $transactions->count(),
            'income_count' => $transactions->where('transaction_type', 'income')->count(),
            'expense_count' => $transactions->where('transaction_type', 'expense')->count(),
            'transactions' => $transactions,
        ];

        return response()->json([
            'success' => true,
            'data' => $summary,
        ]);
    }

    /**
     * Get monthly summary
     */
    public function monthlySummary(Request $request, string $schoolId): JsonResponse
    {
        $year = $request->get('year', date('Y'));
        $sectionId = $request->get('section_id');

        $query = Transaction::where('school_id', $schoolId)
            ->whereYear('transaction_date', $year);

        if ($sectionId) {
            $query->where('section_id', $sectionId);
        }

        $monthlySummary = $query
            ->select(
                DB::raw('MONTH(transaction_date) as month'),
                DB::raw('SUM(CASE WHEN transaction_type = "income" THEN amount ELSE 0 END) as income'),
                DB::raw('SUM(CASE WHEN transaction_type = "expense" THEN amount ELSE 0 END) as expenses')
            )
            ->groupBy(DB::raw('MONTH(transaction_date)'))
            ->orderBy('month')
            ->get()
            ->map(function ($item) {
                $item->balance = $item->income - $item->expenses;
                $item->month_name = date('F', mktime(0, 0, 0, $item->month, 1));

                return $item;
            });

        return response()->json([
            'success' => true,
            'data' => [
                'year' => $year,
                'monthly_data' => $monthlySummary,
                'total_income' => $monthlySummary->sum('income'),
                'total_expenses' => $monthlySummary->sum('expenses'),
                'total_balance' => $monthlySummary->sum('balance'),
            ],
        ]);
    }
}
