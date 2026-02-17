<?php

use App\Http\Controllers\Api\AcademicSessionController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ClassController;
use App\Http\Controllers\Api\ExamController;
use App\Http\Controllers\Api\FeeController;
use App\Http\Controllers\Api\SchoolController;
use App\Http\Controllers\Api\SectionController;
use App\Http\Controllers\Api\StudentController;
use App\Http\Controllers\Api\SubjectController;
use App\Http\Controllers\Api\LessonPlanController;
use App\Http\Controllers\Api\SyllabusController;
use App\Http\Controllers\Api\TermController;
use App\Http\Controllers\Api\TransactionController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\ImportController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\ReportController;
use App\Http\Controllers\Api\TimetableController;
use App\Http\Controllers\Api\HomeworkController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Public routes (no authentication required)
Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/reset-password', [AuthController::class, 'resetPassword']);
    Route::post('/onboard-school', [AuthController::class, 'onboardSchool']);
});

// Protected routes (authentication required)
Route::middleware('auth:api')->group(function () {

    // Auth routes
    Route::prefix('auth')->group(function () {
        Route::post('/logout', [AuthController::class, 'logout']);
        Route::post('/refresh', [AuthController::class, 'refresh']);
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/update-password', [AuthController::class, 'updatePassword']);
    });

    // Schools routes
    Route::apiResource('schools', SchoolController::class);
    Route::get('schools/banks', [SchoolController::class, 'getBanks']);
    Route::get('schools/{school}/statistics', [SchoolController::class, 'statistics']);
    Route::post('schools/{school}/setup-subaccount', [SchoolController::class, 'setupSubaccount']);

    // School-scoped routes
    Route::prefix('schools/{school}')->middleware('school.access')->group(function () {

        // Sections
        Route::apiResource('sections', SectionController::class);
        Route::post('sections/{section}/assign-users', [SectionController::class, 'assignUsers']);
        Route::get('sections/{section}/statistics', [SectionController::class, 'statistics']);

        // Users
        Route::apiResource('users', UserController::class);
        Route::post('users/{user}/assign-sections', [UserController::class, 'assignSections']);

        // Academic Sessions
        Route::apiResource('sessions', AcademicSessionController::class);

        // Terms
        Route::apiResource('terms', TermController::class);

        // Classes
        Route::apiResource('classes', ClassController::class);
        Route::get('classes/{class}/statistics', [ClassController::class, 'statistics']);

        // Subjects
        Route::apiResource('subjects', SubjectController::class);

        // Attendance
        Route::get('attendance', [AttendanceController::class, 'index']);
        Route::post('attendance', [AttendanceController::class, 'store']);
        Route::get('attendance/section-summary', [AttendanceController::class, 'sectionSummary']);
        Route::get('students/{id}/attendance', [AttendanceController::class, 'studentHistory']);

        // Exams & Results
        Route::get('exams', [ExamController::class, 'index']);
        Route::post('exams', [ExamController::class, 'store']);
        Route::get('exams/academic-analytics', [ExamController::class, 'academicAnalytics']);
        Route::get('exams/{exam}/results', [ExamController::class, 'getResults']);
        Route::post('exams/{exam}/results', [ExamController::class, 'saveResults']);

        // Students
        Route::apiResource('students', StudentController::class);
        Route::get('students/{student}/transactions', [StudentController::class, 'transactions']);
        Route::get('students/{student}/payment-summary', [StudentController::class, 'paymentSummary']);
        Route::post('students/import', [StudentController::class, 'import']);

        // Fees
        Route::apiResource('fees', FeeController::class);
        Route::get('fees-summary', [FeeController::class, 'summary']);

        // Lesson Plans & Syllabus
        Route::apiResource('lesson-plans', LessonPlanController::class);
        Route::apiResource('syllabuses', SyllabusController::class);

        // Transactions
        Route::apiResource('transactions', TransactionController::class);
        Route::get('transactions-dashboard-stats', [TransactionController::class, 'dashboardStats']);
        Route::get('transactions-report', [TransactionController::class, 'report']);
        Route::get('transactions-monthly-summary', [TransactionController::class, 'monthlySummary']);

        // Reports
        Route::prefix('reports')->group(function () {
            Route::get('/financial-summary', [ReportController::class, 'financialSummary']);
            Route::get('/payment-methods', [ReportController::class, 'paymentMethods']);
            Route::get('/fee-collection', [ReportController::class, 'feeCollection']);
            Route::get('/debtors', [ReportController::class, 'debtors']);
            Route::get('/academic-report-card/{studentId}', [ReportController::class, 'academicReportCard']);
        });
    });

    // Notifications routes
    Route::prefix('notifications')->group(function () {
        Route::get('/', [NotificationController::class, 'index']);
        Route::get('/unread-count', [NotificationController::class, 'unreadCount']);
        Route::post('/', [NotificationController::class, 'store']);
        Route::post('/{id}/read', [NotificationController::class, 'markAsRead']);
        Route::post('/mark-all-read', [NotificationController::class, 'markAllAsRead']);
        Route::post('/broadcast', [NotificationController::class, 'broadcast']);
        Route::delete('/{id}', [NotificationController::class, 'destroy']);
        Route::delete('/read/all', [NotificationController::class, 'deleteAllRead']);
    });

    // Messages routes
    Route::prefix('messages')->group(function () {
        Route::get('/', [MessageController::class, 'index']);
        Route::get('/conversation/{userId}', [MessageController::class, 'getConversation']);
        Route::get('/unread-count', [MessageController::class, 'unreadCount']);
        Route::get('/contacts', [MessageController::class, 'getContacts']);
        Route::post('/', [MessageController::class, 'store']);
        Route::post('/{id}/read', [MessageController::class, 'markRead']);
        Route::delete('/{id}', [MessageController::class, 'destroy']);
    });

    // Payment routes
    Route::prefix('payments')->group(function () {
        Route::get('/', [PaymentController::class, 'index']);
        Route::post('/initialize', [PaymentController::class, 'initialize']);
        Route::post('/verify', [PaymentController::class, 'verify']);
    });

    // Bulk Import routes
    Route::prefix('import')->group(function () {
        Route::post('/users', [ImportController::class, 'importUsers']);
        Route::post('/students', [ImportController::class, 'importStudents']);
    });
    
    Route::apiResource('timetables', TimetableController::class);
    Route::apiResource('homeworks', HomeworkController::class);

});
