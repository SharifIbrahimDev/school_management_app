<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Exam;
use App\Models\ExamResult;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use App\Models\Notification;
use App\Models\Student;

class ExamController extends Controller
{
    /**
     * Get exams list (filtered by class/subject)
     */
    public function index(Request $request)
    {
        $query = Exam::with(['subject:id,name', 'class:id,class_name']); // optimize select

        if ($request->has('class_id')) {
            $query->where('class_id', $request->class_id);
        }
        if ($request->has('subject_id')) {
            $query->where('subject_id', $request->subject_id);
        }

        $exams = $query->orderBy('date', 'desc')->get();

        return response()->json($exams);
    }

    /**
     * Create a new exam
     */
    public function store(Request $request)
    {
        $request->validate([
            'class_id' => 'required|exists:classes,id',
            'subject_id' => 'required|exists:subjects,id',
            'title' => 'required|string', // Mid-Term, Final
            'max_score' => 'required|integer|min:1',
            'date' => 'nullable|date',
        ]);

        $exam = Exam::create([
            'school_id' => $request->user()->school_id ?? 1,
            'class_id' => $request->class_id,
            'subject_id' => $request->subject_id,
            'title' => $request->title,
            'max_score' => $request->max_score,
            'date' => $request->date,
            // 'term_id', 'session_id' - assume current/active or passed
        ]);

        return response()->json($exam, 201);
    }

    /**
     * Get results for an exam
     */
    public function getResults(Request $request, $examId)
    {
        $results = ExamResult::with('student:id,first_name,last_name,admission_number')
            ->where('exam_id', $examId)
            ->get();

        return response()->json($results);
    }

    /**
     * Save/Update results in bulk
     */
    public function saveResults(Request $request, $examId)
    {
        $request->validate([
            'results' => 'required|array',
            'results.*.student_id' => 'required|exists:students,id',
            'results.*.score' => 'required|numeric|min:0',
        ]);

        DB::beginTransaction();
        try {
            foreach ($request->results as $result) {
                ExamResult::updateOrCreate(
                    [
                        'exam_id' => $examId,
                        'student_id' => $result['student_id'],
                    ],
                    [
                        'score' => $result['score'],
                        'remark' => $result['remark'] ?? null,
                        'graded_by' => $request->user()->id,
                        'grade' => $this->calculateGrade($result['score']), // Auto calc grade?
                    ]
                );
            }
            $this->notifyResultsSaved($examId, $request->results);
            DB::commit();

            return response()->json(['message' => 'Results saved successfully']);
        } catch (\Exception $e) {
            DB::rollBack();

            return response()->json(['message' => 'Failed to save results', 'error' => $e->getMessage()], 500);
        }
    }

    protected function calculateGrade($score)
    {
        if ($score >= 70) {
            return 'A';
        }
        if ($score >= 60) {
            return 'B';
        }
        if ($score >= 50) {
            return 'C';
        }
        if ($score >= 45) {
            return 'D';
        }
        if ($score >= 40) {
            return 'E';
        }

        return 'F';
    }

    /**
     * Get academic analytics for a section
     */
    public function academicAnalytics(Request $request)
    {
        $request->validate([
            'section_id' => 'required|exists:sections,id',
        ]);

        $sectionId = $request->section_id;

        // 1. Average scores per class in this section
        $classAverages = DB::table('exam_results')
            ->join('exams', 'exam_results.exam_id', '=', 'exams.id')
            ->join('classes', 'exams.class_id', '=', 'classes.id')
            ->where('classes.section_id', $sectionId)
            ->select('classes.class_name', DB::raw('AVG(exam_results.score) as average_score'))
            ->groupBy('classes.id', 'classes.class_name')
            ->get();

        // 2. Performance per subject across the section
        $subjectPerformance = DB::table('exam_results')
            ->join('exams', 'exam_results.exam_id', '=', 'exams.id')
            ->join('subjects', 'exams.subject_id', '=', 'subjects.id')
            ->join('classes', 'exams.class_id', '=', 'classes.id')
            ->where('classes.section_id', $sectionId)
            ->select('subjects.name', DB::raw('AVG(exam_results.score) as average_score'))
            ->groupBy('subjects.id', 'subjects.name')
            ->orderBy('average_score', 'desc')
            ->get();

        // 3. Identification of at-risk students (average score < 40%)
        $atRiskStudents = DB::table('exam_results')
            ->join('students', 'exam_results.student_id', '=', 'students.id')
            ->where('students.section_id', $sectionId)
            ->select('students.id', 'students.student_name', DB::raw('AVG(exam_results.score) as average_score'))
            ->groupBy('students.id', 'students.student_name')
            ->having('average_score', '<', 40)
            ->limit(10)
            ->get();

        return response()->json([
            'success' => true,
            'data' => [
                'class_averages' => $classAverages,
                'subject_performance' => $subjectPerformance,
                'at_risk_students' => $atRiskStudents,
            ],
        ]);
    }

    /**
     * Notify parents about new exam results.
     */
    protected function notifyResultsSaved($examId, $results)
    {
        $exam = Exam::with('subject')->find($examId);
        if (!$exam) return;

        $notifications = [];
        foreach ($results as $res) {
            $student = Student::find($res['student_id']);
            if ($student && $student->parent_id) {
                $notifications[] = [
                    'user_id' => $student->parent_id,
                    'type' => 'exam_result_published',
                    'title' => 'New Exam Result Published',
                    'message' => "Exam result for '{$student->student_name}' in '{$exam->subject->name}' has been published.",
                    'data' => json_encode(['exam_id' => $examId, 'student_id' => $student->id]),
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            }
        }

        if (!empty($notifications)) {
            Notification::insert($notifications);
        }
    }
}
