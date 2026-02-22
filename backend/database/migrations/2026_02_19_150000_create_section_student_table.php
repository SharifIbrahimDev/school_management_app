<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Create the pivot table
        Schema::create('section_student', function (Blueprint $table) {
            $table->id();
            $table->foreignId('section_id')->constrained('sections')->onDelete('cascade');
            $table->foreignId('student_id')->constrained('students')->onDelete('cascade');
            $table->timestamps();
        });

        // 2. Migrate existing data if any
        $students = DB::table('students')->whereNotNull('section_id')->get();
        foreach ($students as $student) {
            DB::table('section_student')->insert([
                'section_id' => $student->section_id,
                'student_id' => $student->id,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // 3. Remove the section_id from students table
        Schema::table('students', function (Blueprint $table) {
            $table->dropConstrainedForeignId('section_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // 1. Re-add section_id to students table
        Schema::table('students', function (Blueprint $table) {
            $table->foreignId('section_id')->nullable()->constrained('sections')->onDelete('cascade');
        });

        // 2. Restore data (best effort - takes the first section found)
        $sectionStudents = DB::table('section_student')->get();
        foreach ($sectionStudents as $item) {
            DB::table('students')->where('id', $item->student_id)->update([
                'section_id' => $item->section_id
            ]);
        }

        // 3. Drop the pivot table
        Schema::dropIfExists('section_student');
    }
};
