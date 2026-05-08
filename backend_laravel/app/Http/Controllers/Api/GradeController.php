<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Nilai;
use Illuminate\Http\Request;

class GradeController extends Controller
{
    public function index(Request $request)
    {
        $sekolahId = $request->query('sekolah_id');
        $mapelId = $request->query('mapel_id');
        
        $query = Nilai::with(['siswa', 'mapel']);
        if ($sekolahId) {
            $query->whereHas('siswa', function($q) use ($sekolahId) {
                $q->where('sekolah_id', $sekolahId);
            });
        }
        if ($mapelId) {
            $query->where('mapel_id', $mapelId);
        }
        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'siswa_id' => 'required|exists:siswas,id',
            'mapel_id' => 'required|exists:mapels,id',
            'nilai' => 'required|numeric',
        ]);

        $nilai = Nilai::create($validated);
        return response()->json(['status' => 'success', 'message' => 'Nilai ditambahkan', 'data' => $nilai]);
    }

    public function update(Request $request, Nilai $nilai)
    {
        $validated = $request->validate([
            'nilai' => 'required|numeric',
        ]);

        $nilai->update($validated);
        return response()->json(['status' => 'success', 'message' => 'Nilai diperbarui', 'data' => $nilai]);
    }

    public function destroy(Nilai $nilai)
    {
        $nilai->delete();
        return response()->json(['status' => 'success', 'message' => 'Nilai dihapus']);
    }
}
