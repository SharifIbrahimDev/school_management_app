<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Traits\GeneratesSchoolIds;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    use GeneratesSchoolIds;
    /**
     * Register a new user
     */
    public function register(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'full_name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
            'role' => 'required|in:proprietor,principal,bursar,teacher,parent',
            'school_id' => 'required|exists:schools,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = User::create([
            'full_name' => $request->full_name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => $request->role,
            'school_id' => $request->school_id,
            'is_active' => true,
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'User registered successfully',
            'data' => [
                'user' => $user,
                'token' => $token,
                'token_type' => 'Bearer',
            ],
        ], 201);
    }

    /**
     * Login user and return JWT token
     */
    public function login(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $credentials = $request->only('email', 'password');

        // Will be replaced with JWT authentication
        $user = User::where('email', $request->email)->first();

        if (! $user || ! Hash::check($request->password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Invalid credentials',
            ], 401);
        }

        if (! $user->is_active) {
            return response()->json([
                'success' => false,
                'message' => 'Account is inactive',
            ], 403);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Login successful',
            'data' => [
                'user' => $user->load('school', 'sections'),
                'token' => $token,
                'token_type' => 'Bearer',
            ],
        ]);
    }

    /**
     * Get authenticated user
     */
    public function me(Request $request): JsonResponse
    {
        // Will use JWT auth middleware
        // $user = auth()->user();

        return response()->json([
            'success' => true,
            'data' => [
                'user' => $request->user()->load('school', 'sections'),
            ],
        ]);
    }

    /**
     * Logout user (invalidate token)
     */
    public function logout(Request $request): JsonResponse
    {
        // Revoke the token that was used to authenticate the current request
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'success' => true,
            'message' => 'Successfully logged out',
        ]);
    }

    /**
     * Refresh JWT token
     */
    public function refresh(): JsonResponse
    {
        // Will refresh JWT token
        // $token = auth()->refresh();

        return response()->json([
            'success' => true,
            'data' => [
                // 'token' => $token,
                // 'token_type' => 'bearer',
                // 'expires_in' => auth()->factory()->getTTL() * 60
            ],
        ]);
    }

    /**
     * Request password reset
     */
    public function forgotPassword(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email|exists:users,email',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        // TODO: Implement password reset email
        // Password::sendResetLink($request->only('email'));

        return response()->json([
            'success' => true,
            'message' => 'Password reset link sent to your email',
        ]);
    }

    /**
     * Update authenticated user password
     */
    public function updatePassword(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'current_password' => 'required|string',
            'password' => 'required|string|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        $user = $request->user();

        if (!Hash::check($request->current_password, $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Current password does not match',
            ], 401);
        }

        $user->update([
            'password' => Hash::make($request->password),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Password updated successfully',
        ]);
    }

    /**
     * Onboard a new school and its proprietor
     */
    public function onboardSchool(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            // School details
            'school_name' => 'required|string|max:255',
            'short_code' => 'required|string|max:20|unique:schools,short_code',
            'school_address' => 'nullable|string',
            'school_phone' => 'nullable|string|max:50',
            'school_email' => 'nullable|email|max:255',
            // Proprietor details
            'full_name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'success' => false,
                'errors' => $validator->errors(),
            ], 422);
        }

        return \DB::transaction(function () use ($request) {
            // 1. Create School
            $school = \App\Models\School::create([
                'name' => $request->school_name,
                'short_code' => strtoupper($request->short_code),
                'address' => $request->school_address,
                'phone' => $request->school_phone,
                'email' => $request->school_email,
                'is_active' => true,
            ]);

            // 2. Create Proprietor User
            $registrationId = $this->generateRegistrationId($school->id, 'proprietor');
            
            $user = User::create([
                'registration_id' => $registrationId,
                'full_name' => $request->full_name,
                'email' => $request->email,
                'password' => Hash::make($request->password),
                'role' => 'proprietor',
                'school_id' => $school->id,
                'is_active' => true,
            ]);

            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'success' => true,
                'message' => 'School and proprietor registered successfully',
                'data' => [
                    'school' => $school,
                    'user' => $user->load('school'),
                    'token' => $token,
                    'token_type' => 'Bearer',
                ],
            ], 201);
        });
    }
}
