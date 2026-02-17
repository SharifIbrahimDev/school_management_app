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
        Schema::create('lesson_plans', function (Blueprint $blueprint) {
            $blueprint->id();
            $blueprint->string('school_id'); // Link to school
            $blueprint->unsignedBigInteger('section_id');
            $blueprint->unsignedBigInteger('class_id');
            $blueprint->unsignedBigInteger('subject_id');
            $blueprint->unsignedBigInteger('teacher_id');
            $blueprint->string('title');
            $blueprint->text('content');
            $blueprint->integer('week_number');
            $blueprint->enum('status', ['draft', 'submitted', 'approved', 'rejected'])->default('draft');
            $blueprint->text('remarks')->nullable();
            $blueprint->timestamps();

            $blueprint->foreign('section_id')->references('id')->on('sections')->onDelete('cascade');
            $blueprint->foreign('class_id')->references('id')->on('classes')->onDelete('cascade');
            $blueprint->foreign('subject_id')->references('id')->on('subjects')->onDelete('cascade');
            $blueprint->foreign('teacher_id')->references('id')->on('users')->onDelete('cascade');
        });

        Schema::create('syllabuses', function (Blueprint $blueprint) {
            $blueprint->id();
            $blueprint->string('school_id');
            $blueprint->unsignedBigInteger('section_id');
            $blueprint->unsignedBigInteger('class_id');
            $blueprint->unsignedBigInteger('subject_id');
            $blueprint->string('topic');
            $blueprint->text('description')->nullable();
            $blueprint->enum('status', ['pending', 'in_progress', 'completed'])->default('pending');
            $blueprint->date('completion_date')->nullable();
            $blueprint->timestamps();

            $blueprint->foreign('section_id')->references('id')->on('sections')->onDelete('cascade');
            $blueprint->foreign('class_id')->references('id')->on('classes')->onDelete('cascade');
            $blueprint->foreign('subject_id')->references('id')->on('subjects')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('syllabuses');
        Schema::dropIfExists('lesson_plans');
    }
};
