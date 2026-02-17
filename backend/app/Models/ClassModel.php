<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ClassModel extends Model
{
    use HasFactory;

    protected $table = 'classes';

    protected $fillable = [
        'school_id',
        'section_id',
        'class_name',
        'description',
        'form_teacher_id',
        'capacity',
        'is_active',
    ];

    /**
     * Get the teacher assigned to the class.
     */
    public function formTeacher(): BelongsTo
    {
        return $this->belongsTo(User::class, 'form_teacher_id');
    }

    /**
     * Get the school that owns the class.
     */
    public function school(): BelongsTo
    {
        return $this->belongsTo(School::class);
    }

    /**
     * Get the section that owns the class.
     */
    public function section(): BelongsTo
    {
        return $this->belongsTo(Section::class);
    }

    /**
     * Get the students for the class.
     */
    public function students(): HasMany
    {
        return $this->hasMany(Student::class, 'class_id');
    }

    /**
     * Get the fees for the class.
     */
    public function fees(): HasMany
    {
        return $this->hasMany(Fee::class, 'class_id');
    }
}
