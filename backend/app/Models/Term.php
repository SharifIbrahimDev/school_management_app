<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Term extends Model
{
    use HasFactory;

    protected $fillable = [
        'school_id',
        'section_id',
        'session_id',
        'term_name',
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
     * Get the school that owns the term.
     */
    public function school(): BelongsTo
    {
        return $this->belongsTo(School::class);
    }

    /**
     * Get the section that owns the term.
     */
    public function section(): BelongsTo
    {
        return $this->belongsTo(Section::class);
    }

    /**
     * Get the academic session that owns the term.
     */
    public function academicSession(): BelongsTo
    {
        return $this->belongsTo(AcademicSession::class, 'session_id');
    }

    /**
     * Get the fees for the term.
     */
    public function fees(): HasMany
    {
        return $this->hasMany(Fee::class);
    }

    /**
     * Get the transactions for the term.
     */
    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }
}
