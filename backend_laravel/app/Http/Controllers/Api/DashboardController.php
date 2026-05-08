<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Sekolah;
use App\Models\Guru;
use App\Models\Siswa;
use App\Models\Mapel;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function index(Request $request)
    {
        $sekolahId = $request->query('sekolah_id');
        $sekolahs = Sekolah::all();
        $mapels = Mapel::all();
        
        $querySiswa = Siswa::query();
        $queryGuru = Guru::query();
        
        $tingkat = "";
        if ($sekolahId) {
            $querySiswa->where('sekolah_id', $sekolahId);
            $queryGuru->where('sekolah_id', $sekolahId);
            $currentSekolah = Sekolah::find($sekolahId);
            if ($currentSekolah) {
                $tingkat = $currentSekolah->tingkat;
            }
        }

        return response()->json([
            'appName' => "DRP Absensi",
            'guru' => "Dheri Rama Permadhi, S.Pd",
            'sekolah' => $sekolahs,
            'mapel' => $mapels,
            'totalSiswa' => $querySiswa->count(),
            'totalGuru' => $queryGuru->count(),
            'totalSekolah' => $sekolahs->count(),
            'totalMapel' => $mapels->count(),
            'tingkat' => $tingkat
        ]);
    }
}
