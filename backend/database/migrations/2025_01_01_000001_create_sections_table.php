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
        // 3. Sections Table
        Schema::create('sections', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->onDelete('cascade');
            $table->string('section_name');
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // 4. User-Section Assignment Table (Many-to-Many) - MOVED TO SEPARATE MIGRATION
        // Schema::create('user_section', function (Blueprint $table) {
        //     $table->id();
        //     $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
        //     $table->foreignId('section_id')->constrained('sections')->onDelete('cascade');
        //     $table->timestamp('assigned_at')->useCurrent();
        //     $table->unique(['user_id', 'section_id']);
        // });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('user_section');
        Schema::dropIfExists('sections');
    }
};
