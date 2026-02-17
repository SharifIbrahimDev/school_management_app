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
        // 9. Fees Table
        Schema::create('fees', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->onDelete('cascade');
            $table->foreignId('section_id')->constrained('sections')->onDelete('cascade');
            $table->foreignId('session_id')->constrained('academic_sessions')->onDelete('cascade');
            $table->foreignId('term_id')->constrained('terms')->onDelete('cascade');
            $table->foreignId('class_id')->nullable()->constrained('classes')->onDelete('set null');
            $table->string('fee_name');
            $table->decimal('amount', 10, 2);
            $table->enum('fee_scope', ['class', 'section', 'school']);
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();

            $table->index(['session_id', 'term_id']);
        });

        // 10. Transactions Table
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->onDelete('cascade');
            $table->foreignId('section_id')->constrained('sections')->onDelete('cascade');
            $table->foreignId('session_id')->nullable()->constrained('academic_sessions')->onDelete('set null');
            $table->foreignId('term_id')->nullable()->constrained('terms')->onDelete('set null');
            $table->foreignId('student_id')->nullable()->constrained('students')->onDelete('set null');
            $table->enum('transaction_type', ['income', 'expense']);
            $table->decimal('amount', 10, 2);
            $table->enum('payment_method', ['cash', 'bank_transfer', 'cheque', 'mobile_money']);
            $table->string('category')->nullable();
            $table->text('description')->nullable();
            $table->string('reference_number', 100)->nullable();
            $table->date('transaction_date');
            $table->foreignId('recorded_by')->constrained('users')->onDelete('restrict');
            $table->timestamps();

            $table->index(['school_id', 'section_id']);
            $table->index('student_id');
            $table->index('transaction_date');
            $table->index('transaction_type');
            $table->index(['session_id', 'term_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions');
        Schema::dropIfExists('fees');
    }
};
