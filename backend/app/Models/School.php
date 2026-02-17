<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class School extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'short_code',
        'address',
        'phone',
        'email',
        'logo_url',
        'is_active',
        'paystack_subaccount_code',
        'platform_fee_percentage',
        'settlement_bank',
        'account_number',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    /**
     * Get the users for the school.
     */
    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }

    /**
     * Get the sections for the school.
     */
    public function sections(): HasMany
    {
        return $this->hasMany(Section::class);
    }

    /**
     * Get the academic sessions for the school.
     */
    public function academicSessions(): HasMany
    {
        return $this->hasMany(AcademicSession::class);
    }

    /**
     * Get the classes for the school.
     */
    public function classes(): HasMany
    {
        return $this->hasMany(ClassModel::class);
    }

    /**
     * Get the students for the school.
     */
    public function students(): HasMany
    {
        return $this->hasMany(Student::class);
    }

    /**
     * Get the transactions for the school.
     */
    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }
}
