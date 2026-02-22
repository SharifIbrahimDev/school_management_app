<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\School;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use App\Services\PaystackService;

class SchoolController extends Controller
{
    /**
     * Display a listing of schools
     */
    public function index(): JsonResponse
    {
        $schools = School::with(['users', 'sections'])
            ->where('is_active', true)
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $schools,
        ]);
    }

    /**
     * Store a newly created school
     */
    public function store(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'short_code' => 'required|string|max:10|unique:schools,short_code',
            'address' => 'nullable|string',
            'phone' => 'nullable|string|max:50',
            'email' => 'nullable|email|max:255',
            'logo_url' => 'nullable|url|max:500',
            'paystack_subaccount_code' => 'nullable|string|max:50',
            'platform_fee_percentage' => 'nullable|numeric|min:0|max:100',
            'settlement_bank' => 'nullable|string|max:255',
            'account_number' => 'nullable|string|max:20',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $school = School::create($request->all());

        return response()->json([
            'success' => true,
            'message' => 'School created successfully',
            'data' => $school,
        ], 201);
    }

    /**
     * Display the specified school
     */
    public function show(string $id): JsonResponse
    {
        $school = School::with(['users', 'sections', 'academicSessions', 'classes', 'students'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $school,
        ]);
    }

    /**
     * Update the specified school
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:255',
            'short_code' => 'sometimes|required|string|max:20|unique:schools,short_code,'.$id,
            'address' => 'nullable|string',
            'phone' => 'nullable|string|max:50',
            'email' => 'nullable|email|max:255',
            'logo_url' => 'nullable|url|max:500',
            'is_active' => 'sometimes|boolean',
            'paystack_subaccount_code' => 'nullable|string|max:50',
            'platform_fee_percentage' => 'nullable|numeric|min:0|max:100',
            'settlement_bank' => 'nullable|string|max:255',
            'account_number' => 'nullable|string|max:20',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $school = School::findOrFail($id);
        $oldShortCode = strtoupper($school->short_code);
        $newShortCode = $request->has('short_code') ? strtoupper($request->short_code) : null;

        return \DB::transaction(function () use ($school, $request, $oldShortCode, $newShortCode) {
            $updateData = $request->all();
            if ($newShortCode) {
                $updateData['short_code'] = $newShortCode;
            }
            
            $school->update($updateData);

            if ($newShortCode && $newShortCode !== $oldShortCode) {
                // Update User IDs
                // Search for "OLDCODE-" and replace with "NEWCODE-"
                \App\Models\User::where('school_id', $school->id)
                    ->get()
                    ->each(function ($user) use ($oldShortCode, $newShortCode) {
                        if ($user->registration_id) {
                            $user->registration_id = str_replace($oldShortCode . '-', $newShortCode . '-', $user->registration_id);
                            $user->save();
                        }
                    });

                // Update Student IDs
                \App\Models\Student::where('school_id', $school->id)
                    ->get()
                    ->each(function ($student) use ($oldShortCode, $newShortCode) {
                        if ($student->admission_number) {
                            $student->admission_number = str_replace($oldShortCode . '-', $newShortCode . '-', $student->admission_number);
                            $student->save();
                        }
                    });
            }

            return response()->json([
                'success' => true,
                'message' => 'School updated successfully' . ($newShortCode ? ' and IDs synchronized' : ''),
                'data' => $school,
            ]);
        });
    }

    /**
     * Remove the specified school
     */
    public function destroy(string $id): JsonResponse
    {
        $school = School::findOrFail($id);
        $school->delete();

        return response()->json([
            'success' => true,
            'message' => 'School deleted successfully',
        ]);
    }

    /**
     * Get school statistics
     */
    public function statistics(string $id): JsonResponse
    {
        $school = School::findOrFail($id);

        $stats = [
            'total_users' => $school->users()->count(),
            'total_sections' => $school->sections()->count(),
            'total_students' => $school->students()->count(),
            'total_classes' => $school->classes()->count(),
            'active_sessions' => $school->academicSessions()->where('is_active', true)->count(),
            'users_by_role' => $school->users()
                ->selectRaw('role, COUNT(*) as count')
                ->groupBy('role')
                ->pluck('count', 'role'),
        ];

        return response()->json([
            'success' => true,
            'data' => $stats,
        ]);
    }

    /**
     * Get list of banks from Paystack
     */
    public function getBanks(PaystackService $paystackService): JsonResponse
    {
        $banks = $paystackService->fetchBanks();
        
        return response()->json([
            'success' => true,
            'data' => $banks,
        ]);
    }

    /**
     * Setup Paystack Subaccount for a school
     */
    public function setupSubaccount(Request $request, string $id, PaystackService $paystackService): JsonResponse
    {
        $school = School::findOrFail($id);

        $validator = Validator::make($request->all(), [
            'settlement_bank' => 'required|string',
            'account_number' => 'required|string|size:10',
            'percentage_charge' => 'nullable|numeric|min:0|max:100',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        // Call Paystack to create subaccount
        $paystackData = $paystackService->createSubaccount([
            'business_name' => $school->name,
            'settlement_bank' => $request->settlement_bank,
            'account_number' => $request->account_number,
            'percentage_charge' => $request->percentage_charge ?? $school->platform_fee_percentage ?? 2,
        ]);

        if (isset($paystackData['success']) && $paystackData['success'] === false) {
            return response()->json([
                'success' => false,
                'message' => $paystackData['message'],
            ], 400);
        }

        // Update school with subaccount info
        $school->update([
            'paystack_subaccount_code' => $paystackData['subaccount_code'],
            'settlement_bank' => $request->settlement_bank,
            'account_number' => $request->account_number,
            'platform_fee_percentage' => $request->percentage_charge ?? $school->platform_fee_percentage ?? 2,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Paystack subaccount initialized successfully',
            'data' => $school,
        ]);
    }

    /**
     * Resolve account number to account name
     */
    public function resolveBank(Request $request, PaystackService $paystackService): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'account_number' => 'required|string|size:10',
            'bank_code' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $result = $paystackService->resolveAccount(
            $request->account_number,
            $request->bank_code
        );

        if (isset($result['success']) && $result['success'] === false) {
            return response()->json([
                'success' => false,
                'message' => $result['message'],
            ], 400);
        }

        return response()->json([
            'success' => true,
            'data' => $result,
        ]);
    }
}
