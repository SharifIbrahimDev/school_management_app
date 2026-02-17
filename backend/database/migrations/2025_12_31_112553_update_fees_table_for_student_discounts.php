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
        Schema::table('fees', function (Blueprint $table) {
            $table->foreignId('student_id')->nullable()->after('class_id')->constrained('students')->onDelete('cascade');
            $table->index('student_id');
        });

        // Update enum to include 'student'
        if (DB::getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE fees MODIFY COLUMN fee_scope ENUM('class', 'section', 'school', 'student') NOT NULL");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('fees', function (Blueprint $table) {
            $table->dropForeign(['student_id']);
            $table->dropColumn('student_id');
        });

        if (DB::getDriverName() === 'mysql') {
            DB::statement("ALTER TABLE fees MODIFY COLUMN fee_scope ENUM('class', 'section', 'school') NOT NULL");
        }
    }
};
