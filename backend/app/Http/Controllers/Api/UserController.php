<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Traits\GeneratesSchoolIds;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{
    use GeneratesSchoolIds;
    /**
     * Display users for a school
     */
    public function index(Request $request, string $schoolId): JsonResponse
    {
        $users = User::where('school_id', $schoolId)
            ->with(['school', 'sections'])
            ->when($request->has('role'), function ($query) use ($request) {
                $query->where('role', $request->role);
            })
            ->when($request->has('is_active'), function ($query) use ($request) {
                $query->where('is_active', $request->boolean('is_active'));
            })
            ->paginate(15);

        return response()->json([
            'success' => true,
            'data' => $users,
        ]);
    }

    /**
     * Store a newly created user
     */
    public function store(Request $request, string $schoolId): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'full_name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'password' => 'required|string|min:8',
            'role' => 'required|in:proprietor,principal,bursar,teacher,parent',
            'phone_number' => 'nullable|string|max:20',
            'address' => 'nullable|string',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $registrationId = $this->generateRegistrationId((int)$schoolId, $request->role);

        $user = User::create([
            'school_id' => $schoolId,
            'registration_id' => $registrationId,
            'full_name' => $request->full_name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => $request->role,
            'phone_number' => $request->phone_number,
            'address' => $request->address,
            'is_active' => $request->is_active ?? true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'User created successfully',
            'data' => $user,
        ], 201);
    }

    /**
     * Display the specified user
     */
    public function show(string $schoolId, string $id): JsonResponse
    {
        $user = User::where('school_id', $schoolId)
            ->with(['school', 'sections', 'recordedTransactions', 'classes', 'subjects', 'students'])
            ->findOrFail($id);

        return response()->json([
            'success' => true,
            'data' => $user,
        ]);
    }

    /**
     * Update the specified user
     */
    public function update(Request $request, string $schoolId, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'full_name' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|required|email|unique:users,email,'.$id,
            'password' => 'sometimes|string|min:8',
            'role' => 'sometimes|required|in:proprietor,principal,bursar,teacher,parent',
            'phone_number' => 'sometimes|nullable|string|max:20',
            'address' => 'sometimes|nullable|string',
            'is_active' => 'sometimes|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = User::where('school_id', $schoolId)->findOrFail($id);

        $data = $request->except('password');
        if ($request->has('password')) {
            $data['password'] = Hash::make($request->password);
        }

        $user->update($data);

        return response()->json([
            'success' => true,
            'message' => 'User updated successfully',
            'data' => $user,
        ]);
    }

    /**
     * Remove the specified user
     */
    public function destroy(string $schoolId, string $id): JsonResponse
    {
        $user = User::where('school_id', $schoolId)->findOrFail($id);
        $user->delete();

        return response()->json([
            'success' => true,
            'message' => 'User deleted successfully',
        ]);
    }

    /**
     * Assign sections to a user
     */
    public function assignSections(Request $request, string $schoolId, string $id): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'section_ids' => 'required|array',
            'section_ids.*' => 'exists:sections,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = User::where('school_id', $schoolId)->findOrFail($id);
        $user->sections()->sync($request->section_ids);

        return response()->json([
            'success' => true,
            'message' => 'Sections assigned to user successfully',
            'data' => $user->load('sections'),
        ]);
    }
}
