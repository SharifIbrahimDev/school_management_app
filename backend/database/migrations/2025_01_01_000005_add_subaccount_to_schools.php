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
        Schema::table('schools', function (Blueprint $table) {
            $table->string('paystack_subaccount_code')->nullable()->after('is_active');
            $table->decimal('platform_fee_percentage', 5, 2)->default(2.00)->after('paystack_subaccount_code');
            $table->string('settlement_bank')->nullable()->after('platform_fee_percentage');
            $table->string('account_number')->nullable()->after('settlement_bank');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('schools', function (Blueprint $table) {
            $table->dropColumn([
                'paystack_subaccount_code',
                'platform_fee_percentage',
                'settlement_bank',
                'account_number',
            ]);
        });
    }
};
