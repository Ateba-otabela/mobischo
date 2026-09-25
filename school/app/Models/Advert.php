<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Advert extends Model
{
    use HasFactory;

    protected $table = 'adverts';

    protected $fillable = [
        'name',
        'phone',
        'type',
        'isDeleted',
        'video',
        'package',
        'link',
        'images',
        'description',
        'towns',
        'logo',
        'isPopular',
        'department',
        'language',
        'group',
    ];

    protected $casts = [
        'isDeleted' => 'boolean',
        'isPopular' => 'boolean',
    ];
}
