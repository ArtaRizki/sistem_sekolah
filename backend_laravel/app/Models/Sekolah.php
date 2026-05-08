<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Sekolah extends Model
{
    protected $fillable = ['nama', 'alamat', 'tingkat'];

    public function gurus() { return $this->hasMany(Guru::class); }
    public function siswas() { return $this->hasMany(Siswa::class); }
    public function mapels() { return $this->hasMany(Mapel::class); }
    public function absensis() { return $this->hasMany(Absensi::class); }
}
