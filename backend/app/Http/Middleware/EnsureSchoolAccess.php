<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureSchoolAccess
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        $schoolId = $request->route('school');

        // Allow super admin (if implemented in future) or check if user belongs to school
        if ($user && $user->school_id == $schoolId) {
            return $next($request);
        }

        return response()->json([
            'success' => false,
            'message' => 'Unauthorized access to this school.',
        ], 403);
    }
}
