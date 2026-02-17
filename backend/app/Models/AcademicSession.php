<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AcademicSession extends Model
{
    use HasFactory;

    protected $fillable = [
        'school_id',
        'section_id',
        'session_name',
        'start_date',
        'end_date',
        'is_active',
    ];

    protected $casts = [
        'start_date' => 'date',
        'end_date' => 'date',
        'is_active' => 'boolean',
    ];

    /**
     * Get the school that owns the session.
     */
    public function school(): BelongsTo
    {
        return $this->belongsTo(School::class);
    }

    /**
     * Get the section that owns the session.
     */
    public function section(): BelongsTo
    {
        return $this->belongsTo(Section::class);
    }

    /**
     * Get the terms for the session.
     */
    public function terms(): HasMany
    {
        return $this->hasMany(Term::class, 'session_id');
    }

    /**
     * Get the fees for the session.
     */
    public function fees(): HasMany
    {
        return $this->hasMany(Fee::class, 'session_id');
    }

    /**
     * Get the transactions for the session.
     */
    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class, 'session_id');
    }
}
