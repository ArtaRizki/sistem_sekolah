<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Siswa extends Model
{
    protected $fillable = ['nama', 'nis', 'jk', 'kelas', 'sekolah_id'];

    public function sekolah() { return $this->belongsTo(Sekolah::class); }
    public function nilais() { return $this->hasMany(Nilai::class); }
    public function absensis() { return $this->hasMany(Absensi::class); }
    public function wajah() { return $this->hasOne(Wajah::class); }
}
