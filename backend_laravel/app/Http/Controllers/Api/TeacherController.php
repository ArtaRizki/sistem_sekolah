<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Guru;
use Illuminate\Http\Request;

class TeacherController extends Controller
{
    public function index(Request $request)
    {
        $sekolahId = $request->query('sekolah_id');
        $sekolahName = $request->query('sekolah');
        
        $query = Guru::query();
        if ($sekolahId) {
            $query->where('sekolah_id', $sekolahId);
        } elseif ($sekolahName) {
            $query->whereHas('sekolah', function($q) use ($sekolahName) {
                $q->where('nama', $sekolahName);
            });
        }
        
        $gurus = $query->with('sekolah')->get()->map(function($guru) {
            return [
                'id' => $guru->id,
                'nama' => $guru->nama,
                'nip' => $guru->nip,
                'mapel' => $guru->mapel,
                'sekolah' => $guru->sekolah->nama ?? '',
                'rowKey' => (string)$guru->id, // For Flutter compatibility
            ];
        });
        return response()->json($gurus);
    }

    public function store(Request $request)
    {
        $sekolahId = $request->sekolah_id;
        if (!$sekolahId && $request->sekolah) {
            $sekolah = Sekolah::where('nama', $request->sekolah)->first();
            $sekolahId = $sekolah?->id;
        }

        $validated = $request->validate([
            'nama' => 'required|string',
            'nip' => 'required|string|unique:gurus',
            'mapel' => 'required|string',
        ]);
        
        if (!$sekolahId) {
            return response()->json(['status' => 'error', 'message' => 'Sekolah tidak ditemukan'], 422);
        }

        $guru = Guru::create(array_merge($validated, ['sekolah_id' => $sekolahId]));
        return response()->json(['status' => 'success', 'message' => 'Guru ditambahkan', 'data' => $guru]);
    }

    public function update(Request $request, Guru $guru)
    {
        $validated = $request->validate([
            'nama' => 'sometimes|required|string',
            'nip' => 'sometimes|required|string|unique:gurus,nip,' . $guru->id,
            'mapel' => 'sometimes|required|string',
            'sekolah_id' => 'sometimes|required|exists:sekolahs,id',
        ]);

        $guru->update($validated);
        return response()->json(['status' => 'success', 'message' => 'Guru diperbarui', 'data' => $guru]);
    }

    public function destroy(Guru $guru)
    {
        $guru->delete();
        return response()->json(['status' => 'success', 'message' => 'Guru dihapus']);
    }
}
