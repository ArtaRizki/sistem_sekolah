<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Absensi extends Model
{
    protected $fillable = ['siswa_id', 'status', 'similarity', 'device_timestamp', 'sekolah_id'];

    public function siswa() { return $this->belongsTo(Siswa::class); }
    public function sekolah() { return $this->belongsTo(Sekolah::class); }
}
