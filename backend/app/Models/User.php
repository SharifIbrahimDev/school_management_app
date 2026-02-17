<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use App\Traits\GeneratesSchoolIds;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, Notifiable, GeneratesSchoolIds;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'registration_id',
        'firebase_uid',
        'email',
        'password',
        'full_name',
        'phone_number',
        'address',
        'role',
        'school_id',
        'is_active',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'is_active' => 'boolean',
        ];
    }

    /**
     * Get the school that owns the user.
     */
    public function school(): BelongsTo
    {
        return $this->belongsTo(School::class);
    }

    /**
     * The sections that belong to the user.
     */
    public function sections(): BelongsToMany
    {
        return $this->belongsToMany(Section::class, 'user_section')
            ->withTimestamps();
    }

    /**
     * Get the transactions recorded by the user.
     */
    public function recordedTransactions(): HasMany
    {
        return $this->hasMany(Transaction::class, 'recorded_by');
    }

    /**
     * The classes where the user is a form teacher.
     */
    public function classes(): HasMany
    {
        return $this->hasMany(ClassModel::class, 'form_teacher_id');
    }

    /**
     * The subjects taught by the user.
     */
    public function subjects(): HasMany
    {
        return $this->hasMany(Subject::class, 'teacher_id');
    }

    /**
     * The students linked to the user (if parent).
     */
    public function students(): HasMany
    {
        return $this->hasMany(Student::class, 'parent_id');
    }

    /**
     * Check if user has a specific role.
     */
    public function hasRole(string $role): bool
    {
        return $this->role === $role;
    }

    /**
     * Check if user has any of the given roles.
     */
    public function hasAnyRole(array $roles): bool
    {
        return in_array($this->role, $roles);
    }

    /**
     * Boot the model.
     */
    protected static function booted()
    {
        static::creating(function ($user) {
            if (!$user->registration_id && $user->school_id && $user->role) {
                $user->registration_id = $user->generateRegistrationId($user->school_id, $user->role);
            }
        });
    }
}
