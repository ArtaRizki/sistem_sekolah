<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Guru extends Model
{
    protected $fillable = ['nama', 'nip', 'mapel', 'sekolah_id'];

    public function sekolah() { return $this->belongsTo(Sekolah::class); }
}
