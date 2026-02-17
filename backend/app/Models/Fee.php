<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Fee extends Model
{
    use HasFactory;

    protected $fillable = [
        'school_id',
        'section_id',
        'session_id',
        'term_id',
        'class_id',
        'student_id',
        'fee_name',
        'amount',
        'fee_scope',
        'description',
        'is_active',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'is_active' => 'boolean',
    ];

    /**
     * Get the student that owns the fee (if student-specific).
     */
    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    /**
     * Get the school that owns the fee.
     */
    public function school(): BelongsTo
    {
        return $this->belongsTo(School::class);
    }

    /**
     * Get the section that owns the fee.
     */
    public function section(): BelongsTo
    {
        return $this->belongsTo(Section::class);
    }

    /**
     * Get the academic session that owns the fee.
     */
    public function academicSession(): BelongsTo
    {
        return $this->belongsTo(AcademicSession::class, 'session_id');
    }

    /**
     * Get the term that owns the fee.
     */
    public function term(): BelongsTo
    {
        return $this->belongsTo(Term::class);
    }

    /**
     * Get the class that owns the fee (if class-specific).
     */
    public function classModel(): BelongsTo
    {
        return $this->belongsTo(ClassModel::class, 'class_id');
    }
}
