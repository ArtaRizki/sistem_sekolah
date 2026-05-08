<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Mapel extends Model
{
    protected $fillable = ['nama', 'kode', 'sekolah_id'];

    public function sekolah() { return $this->belongsTo(Sekolah::class); }
    public function nilais() { return $this->hasMany(Nilai::class); }
}
