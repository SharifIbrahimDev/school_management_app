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
        Schema::table('classes', function (Blueprint $table) {
            $table->foreignId('form_teacher_id')->nullable()->constrained('users')->onDelete('set null')->after('description');
            $table->integer('capacity')->nullable()->after('form_teacher_id');
            $table->boolean('is_active')->default(true)->after('capacity');
        });

        Schema::table('students', function (Blueprint $table) {
            $table->foreignId('parent_id')->nullable()->constrained('users')->onDelete('set null')->after('class_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('students', function (Blueprint $table) {
            $table->dropConstrainedForeignId('parent_id');
        });

        Schema::table('classes', function (Blueprint $table) {
            $table->dropConstrainedForeignId('form_teacher_id');
            $table->dropColumn(['capacity', 'is_active']);
        });
    }
};
