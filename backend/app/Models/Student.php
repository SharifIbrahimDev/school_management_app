<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use App\Traits\GeneratesSchoolIds;

class Student extends Model
{
    use HasFactory, GeneratesSchoolIds;

    protected $fillable = [
        'school_id',
        'class_id',
        'parent_id',
        'student_name',
        'admission_number',
        'date_of_birth',
        'gender',
        'address',
        'parent_name',
        'parent_phone',
        'parent_email',
        'photo_url',
        'is_active',
    ];

    /**
     * Get the parent user associated with the student.
     */
    public function parent(): BelongsTo
    {
        return $this->belongsTo(User::class, 'parent_id');
    }

    protected $casts = [
        'date_of_birth' => 'date',
        'is_active' => 'boolean',
    ];

    /**
     * Get the school that owns the student.
     */
    public function school(): BelongsTo
    {
        return $this->belongsTo(School::class);
    }

    /**
     * The sections that belong to the student.
     */
    public function sections(): BelongsToMany
    {
        return $this->belongsToMany(Section::class, 'section_student')
            ->withTimestamps();
    }

    /**
     * Get the class that owns the student.
     */
    public function classModel(): BelongsTo
    {
        return $this->belongsTo(ClassModel::class, 'class_id');
    }

    /**
     * Get the transactions for the student.
     */
    public function transactions(): HasMany
    {
        return $this->hasMany(Transaction::class);
    }

    /**
     * Get the fees for the student (student-specific fees).
     */
    public function fees(): HasMany
    {
        return $this->hasMany(Fee::class);
    }

    /**
     * Boot the model.
     */
    protected static function booted()
    {
        static::creating(function ($student) {
            if (!$student->admission_number && $student->school_id) {
                $student->admission_number = $student->generateAdmissionNumber($student->school_id);
            }
        });
    }
}
