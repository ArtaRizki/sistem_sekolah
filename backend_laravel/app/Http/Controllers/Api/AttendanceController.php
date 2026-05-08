<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Absensi;
use App\Models\Wajah;
use App\Models\Siswa;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    public function registerFace(Request $request)
    {
        $validated = $request->validate([
            'nis' => 'required|string|exists:siswas,nis',
            'embedding' => 'required|array',
        ]);

        $siswa = Siswa::where('nis', $validated['nis'])->first();
        
        $wajah = Wajah::updateOrCreate(
            ['siswa_id' => $siswa->id],
            ['embedding' => json_encode($validated['embedding'])]
        );

        return response()->json(['status' => 'success', 'message' => 'Face registered', 'id' => $siswa->nis]);
    }

    public function submitAttendance(Request $request)
    {
        $validated = $request->validate([
            'nis' => 'required|string|exists:siswas,nis',
            'status' => 'sometimes|string',
            'similarity' => 'sometimes|numeric',
            'timestamp' => 'sometimes|string',
        ]);

        $siswa = Siswa::where('nis', $validated['nis'])->first();
        
        $absensi = Absensi::create([
            'siswa_id' => $siswa->id,
            'status' => $validated['status'] ?? 'Hadir',
            'similarity' => $validated['similarity'] ?? 0,
            'device_timestamp' => $validated['timestamp'] ?? now()->toIso8601String(),
            'sekolah_id' => $siswa->sekolah_id,
        ]);

        return response()->json(['status' => 'success', 'message' => 'Attendance recorded']);
    }

    public function getSiswaWajah(Request $request)
    {
        $sekolahId = $request->query('sekolah_id');
        $query = Siswa::whereHas('wajah');
        if ($sekolahId) {
            $query->where('sekolah_id', $sekolahId);
        }
        
        $siswas = $query->with('wajah')->get()->map(function($siswa) {
            return [
                'nama' => $siswa->nama,
                'nis' => $siswa->nis,
                'kelas' => $siswa->kelas,
                'sekolah' => $siswa->sekolah->nama ?? '',
                'embedding' => json_decode($siswa->wajah->embedding)
            ];
        });

        return response()->json($siswas);
    }

    public function getRekap(Request $request)
    {
        $sekolahId = $request->query('sekolah_id');
        $bulan = $request->query('bulan'); // YYYY-MM
        
        $query = Absensi::with('siswa');
        if ($sekolahId) {
            $query->where('sekolah_id', $sekolahId);
        }
        if ($bulan) {
            $query->where('created_at', 'like', $bulan . '%');
        }

        $absensis = $query->get();
        $rekap = [];

        foreach ($absensis as $a) {
            $nama = $a->siswa->nama;
            if (!isset($rekap[$nama])) {
                $rekap[$nama] = [
                    'nama' => $nama,
                    'hadir' => 0,
                    'izin' => 0,
                    'sakit' => 0,
                    'alpa' => 0,
                    'total' => 0,
                    'sekolah' => $a->sekolah->nama ?? ''
                ];
            }
            $rekap[$nama]['total']++;
            $status = strtolower($a->status);
            if ($status === 'hadir') $rekap[$nama]['hadir']++;
            elseif ($status === 'izin') $rekap[$nama]['izin']++;
            elseif ($status === 'sakit') $rekap[$nama]['sakit']++;
            else $rekap[$nama]['alpa']++;
        }

        $result = [];
        foreach ($rekap as $r) {
            $r['persen'] = $r['total'] > 0 ? round(($r['hadir'] / $r['total']) * 100) : 0;
            $result[] = $r;
        }

        return response()->json($result);
    }
}
