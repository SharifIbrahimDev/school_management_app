<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Exam extends Model
{
    use HasFactory;

    protected $fillable = [
        'school_id',
        'subject_id',
        'class_id',
        'term_id',
        'session_id',
        'title',
        'max_score',
        'date',
    ];

    public function subject()
    {
        return $this->belongsTo(Subject::class);
    }

    public function class()
    {
        return $this->belongsTo(ClassModel::class, 'class_id');
    }

    public function results()
    {
        return $this->hasMany(ExamResult::class);
    }
}
