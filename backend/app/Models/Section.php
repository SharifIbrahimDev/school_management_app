<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Section extends Model
{
    use HasFactory;

    protected $fillable = [
        'school_id',
        'section_name',
        'description',
        'is_active',
    ];

    protected $casts = [
        'is_active' => 'boolean',
    ];

    /**
     * Get the school that owns the section.
     */
    public function school(): BelongsTo
    {
        return $this->belongsTo(School::class);
    }

    /**
     * The users that belong to the section.
     */
    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'user_section')
            ->withTimestamps();
    }

    /**
     * Get the academic sessions for the section.
     */
    public function academicSessions(): HasMany
    {
        return $this->hasMany(AcademicSession::class);
    }

    /**
     * Get the classes for the section.
     */
    public function classes(): HasMany
    {
        return $this->hasMany(ClassModel::class);
    }

    /**
     * The students that belong to the section.
     */
    public function students(): BelongsToMany
    {
        return $this->belongsToMany(Student::class, 'section_student')
            ->withTimestamps();
    }

    /**
     * Get the transactions for the section.
     */
    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }
}
