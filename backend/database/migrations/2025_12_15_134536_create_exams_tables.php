<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Exams Table
        Schema::create('exams', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained()->onDelete('cascade');
            $table->foreignId('subject_id')->constrained('subjects')->onDelete('cascade');
            $table->foreignId('class_id')->constrained('classes')->onDelete('cascade');
            $table->foreignId('term_id')->nullable()->constrained('terms')->onDelete('cascade');
            $table->foreignId('session_id')->nullable()->constrained('academic_sessions')->onDelete('cascade');
            $table->string('title'); // e.g., "Mid-Term", "Final"
            $table->integer('max_score')->default(100);
            $table->date('date')->nullable();
            $table->timestamps();
        });

        // Exam Results Table
        Schema::create('exam_results', function (Blueprint $table) {
            $table->id();
            $table->foreignId('exam_id')->constrained('exams')->onDelete('cascade');
            $table->foreignId('student_id')->constrained('students')->onDelete('cascade');
            $table->decimal('score', 5, 2);
            $table->string('grade')->nullable(); // A, B, C etc.
            $table->string('remark')->nullable();
            $table->foreignId('graded_by')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamps();

            $table->unique(['exam_id', 'student_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('exam_results');
        Schema::dropIfExists('exams');
    }
};
