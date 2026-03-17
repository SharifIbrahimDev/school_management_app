<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Fee;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class FeeController extends Controller
{
    /**
     * Display fees for a school
     */
    public function index(Request $request, string $schoolId): JsonResponse
    {
        $fees = Fee::where('school_id', $schoolId)
            ->with(['section', 'academicSession', 'term', 'classModel'])
            ->when($request->has('student_id'), function ($query) use ($request) {
                // When we request fees for a specific student, we want all applicable fees:
                // School-wide, Section-wide, Class-wide (for their class), and Student-specific.
                $student = \App\Models\Student::with('sections')->find($request->student_id);
                if ($student) {
                    $sectionIds = $student->sections->pluck('id')->toArray();
                    $query->where(function ($q) use ($student, $sectionIds) {
                        // Section-wide fees (class_id and student_id are null)
                        $q->where(function ($subQ) use ($sectionIds) {
                            $subQ->whereIn('section_id', $sectionIds)
                                 ->whereNull('class_id')
                                 ->whereNull('student_id');
                        })
                        // Class-specific fees
                        ->orWhere(function ($subQ) use ($student) {
                            $subQ->where('class_id', $student->class_id)
                                 ->whereNull('student_id');
                        })
                        // Student-specific fees (inclusive of discounts/scholarships)
                        ->orWhere('student_id', $student->id)
                        // School-wide fees
                        ->orWhere('fee_scope', 'school');
                    });
                } else {
                    $query->where('student_id', $request->student_id);
                }
            }, function ($query) use ($request) {
                // If NO student_id is passed, do the regular exact match (used in Fee List Screen)
                $query->when($request->has('class_id'), function ($q) use ($request) {
                    $q->where('class_id', $request->class_id);
                })
                ->when($request->has('section_id'), function ($q) use ($request) {
                    $q->where('section_id', $request->section_id);
                });
            })
            ->when($request->has('session_id'), function ($query) use ($request) {
                $query->where('session_id', $request->session_id);
            })
            ->when($request->has('term_id'), function ($query) use ($request) {
                $query->where('term_id', $request->term_id);
            })
            ->when($request->has('fee_scope'), function ($query) use ($request) {
                $query->where('fee_scope', $request->fee_scope);
            })
            ->when($request->has('is_active'), function ($query) use ($request) {
                $query->where('is_active', $request->boolean('is_active'));
            })
            ->orderBy('created_at', 'desc')
            ->paginate(100);

        if ($request->has('student_id')) {
            $studentId = $request->student_id;
            $feeIds = collect($fees->items())->pluck('id')->toArray();
            
            $payments = Transaction::where('student_id', $studentId)
                ->whereIn('fee_id', $feeIds)
                ->where('transaction_type', 'income')
                ->where('status', 'approved')
                ->select('fee_id', DB::raw('SUM(amount) as paid_amount'))
                ->groupBy('fee_id')
                ->get()
                ->keyBy('fee_id');

            foreach ($fees->items() as $fee) {
                $paid = isset($payments[$fee->id]) ? (float)$payments[$fee->id]->paid_amount : 0.0;
                $fee->paid_amount = $paid;
                $fee->balance = (float)$fee->amount - $paid;
                $fee->status = $fee->balance <= 0 ? 'paid' : ($paid > 0 ? 'partial' : 'pending');
            }
        }

        return response()->json([
            'success' => true,
            'data' => $fees,
        ]);
    }

    /**
     * Store a newly created fee
     */
    public function store(Request $request, string $schoolId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'required|exists:sections,id',
            'session_id' => 'required|exists:academic_sessions,id',
            'term_id' => 'required|exists:terms,id',
            'class_id' => 'nullable|exists:classes,id',
            'fee_name' => 'required|string|max:255',
            'amount' => 'required|numeric',
            'fee_scope' => 'required|in:class,section,school,student',
            'student_id' => 'nullable|exists:students,id',
            'description' => 'nullable|string',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        // Validate fee_scope and class_id relationship
        if ($request->fee_scope === 'class' && ! $request->class_id) {
            return response()->json([
                'success' => false,
                'message' => 'class_id is required when fee_scope is "class"',
            ], 422);
        }

        if ($request->fee_scope === 'student' && ! $request->student_id) {
            return response()->json([
                'success' => false,
                'message' => 'student_id is required when fee_scope is "student"',
            ], 422);
        }

        $fee = Fee::create([
            'school_id' => $schoolId,
            'section_id' => $request->section_id,
            'session_id' => $request->session_id,
            'term_id' => $request->term_id,
            'class_id' => $request->class_id,
            'student_id' => $request->student_id,
            'fee_name' => $request->fee_name,
            'amount' => $request->amount,
            'fee_scope' => $request->fee_scope,
            'description' => $request->description,
            'is_active' => $request->is_active ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Fee created successfully',
            'data' => $fee->load(['section', 'academicSession', 'term', 'classModel']),
        ], 201);
    }

    /**
     * Display the specified fee
     */
    public function show(string $schoolId, string $id): JsonResponse
    {
        $fee = Fee::where('school_id', $schoolId)
            ->with(['section', 'academicSession', 'term', 'classModel'])
            ->findOrFail($id);

        if ($request->has('student_id')) {
            $paid = Transaction::where('student_id', $request->student_id)
                ->where('fee_id', $id)
                ->where('transaction_type', 'income')
                ->where('status', 'approved')
                ->sum('amount');
            
            $fee->paid_amount = (float)$paid;
            $fee->balance = (float)$fee->amount - (float)$paid;
            $fee->status = $fee->balance <= 0 ? 'paid' : ($paid > 0 ? 'partial' : 'pending');
        }

        return response()->json([
            'success' => true,
            'data' => $fee,
        ]);
    }

    /**
     * Update the specified fee
     */
    public function update(Request $request, string $schoolId, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_id' => 'sometimes|required|exists:sections,id',
            'session_id' => 'sometimes|required|exists:academic_sessions,id',
            'term_id' => 'sometimes|required|exists:terms,id',
            'class_id' => 'nullable|exists:classes,id',
            'fee_name' => 'sometimes|required|string|max:255',
            'amount' => 'sometimes|required|numeric',
            'fee_scope' => 'sometimes|required|in:class,section,school,student',
            'student_id' => 'nullable|exists:students,id',
            'description' => 'nullable|string',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $fee = Fee::where('school_id', $schoolId)->findOrFail($id);
        $fee->update($request->all());

        return response()->json([
            'success' => true,
            'message' => 'Fee updated successfully',
            'data' => $fee->load(['section', 'academicSession', 'term', 'classModel']),
        ]);
    }

    /**
     * Remove the specified fee
     */
    public function destroy(string $schoolId, string $id): JsonResponse
    {
        $fee = Fee::where('school_id', $schoolId)->findOrFail($id);
        $fee->delete();

        return response()->json([
            'success' => true,
            'message' => 'Fee deleted successfully',
        ]);
    }

    /**
     * Get fee summary by scope with actual expected totals
     */
    public function summary(Request $request, string $schoolId): JsonResponse
    {
        $sectionId = $request->section_id;
        $sessionId = $request->session_id;
        $termId = $request->term_id;

        $query = Fee::where('school_id', $schoolId)
            ->where('is_active', true);

        if ($sectionId) {
            $query->where('section_id', $sectionId);
        }
        if ($sessionId) {
            $query->where('session_id', $sessionId);
        }
        if ($termId) {
            $query->where('term_id', $termId);
        }

        $fees = $query->get();
        $totalExpected = 0;

        foreach ($fees as $fee) {
            $studentsCount = 0;
            if ($fee->fee_scope === 'school') {
                $studentsCount = \App\Models\Student::where('school_id', $schoolId)
                    ->where('is_active', true)
                    ->when($sectionId, function($q) use ($sectionId) {
                        return $q->whereHas('sections', function($sq) use ($sectionId) {
                            $sq->where('sections.id', $sectionId);
                        });
                    })->count();
            } elseif ($fee->fee_scope === 'section') {
                $studentsCount = \App\Models\Student::whereHas('sections', function($q) use ($fee) {
                        $q->where('sections.id', $fee->section_id);
                    })
                    ->where('is_active', true)
                    ->count();
            } elseif ($fee->fee_scope === 'class') {
                $studentsCount = \App\Models\Student::where('class_id', $fee->class_id)
                    ->where('is_active', true)
                    ->count();
            } elseif ($fee->fee_scope === 'student') {
                $studentsCount = 1;
            }
            $totalExpected += ($fee->amount * $studentsCount);
        }

        // Calculate collected for these specific fees
        $feeIds = $fees->pluck('id')->toArray();
        $totalCollected = \App\Models\Transaction::where('school_id', $schoolId)
            ->where('transaction_type', 'income')
            ->where('status', 'approved')
            ->where(function ($q) use ($feeIds) {
                $q->whereIn('fee_id', $feeIds)
                  ->orWhere(function ($sq) {
                      $sq->whereNull('fee_id')
                         ->where('category', 'like', '%Fee%');
                  });
            });

        if ($sectionId) {
            $totalCollected->where('section_id', $sectionId);
        }
        if ($sessionId) {
            $totalCollected->where('session_id', $sessionId);
        }
        if ($termId) {
            $totalCollected->where('term_id', $termId);
        }

        $totalCollected = $totalCollected->sum('amount');

        $summary = [
            'total_amount' => (float)$totalExpected,
            'total_balance' => (float)max(0, $totalExpected - $totalCollected),
            'total_collected' => (float)$totalCollected,
            'fees_count' => $fees->count(),
            'fees_by_scope' => $fees->groupBy('fee_scope')->map(function($group) {
                return [
                    'count' => $group->count(),
                    'total_rates' => $group->sum('amount'),
                ];
            }),
        ];

        return response()->json([
            'success' => true,
            'data' => $summary,
        ]);
    }
}
