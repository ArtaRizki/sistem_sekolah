<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Nilai extends Model
{
    protected $fillable = ['siswa_id', 'mapel_id', 'nilai'];

    public function siswa() { return $this->belongsTo(Siswa::class); }
    public function mapel() { return $this->belongsTo(Mapel::class); }
}
