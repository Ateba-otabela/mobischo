<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserDevice extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_code',
        'fcm_token',
        'token_hash',
        'platform',
        'is_active',
        'revoked_at',
        'last_seen_at',
        'token_updated_at',
    ];

    protected $hidden = [
        'fcm_token',
        'token_hash',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'revoked_at' => 'datetime',
        'last_seen_at' => 'datetime',
        'token_updated_at' => 'datetime',
    ];
}