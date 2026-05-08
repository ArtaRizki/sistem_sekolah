<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Siswa;
use Illuminate\Http\Request;

class StudentController extends Controller
{
    public function index(Request $request)
    {
        $sekolahId = $request->query('sekolah_id');
        $sekolahName = $request->query('sekolah');
        $kelas = $request->query('kelas');
        
        $query = Siswa::query();
        if ($sekolahId) {
            $query->where('sekolah_id', $sekolahId);
        } elseif ($sekolahName) {
            $query->whereHas('sekolah', function($q) use ($sekolahName) {
                $q->where('nama', $sekolahName);
            });
        }
        if ($kelas) {
            $query->where('kelas', $kelas);
        }
        
        $siswas = $query->with('sekolah')->get()->map(function($siswa) {
            return [
                'id' => $siswa->id,
                'nama' => $siswa->nama,
                'nis' => $siswa->nis,
                'jk' => $siswa->jk,
                'kelas' => $siswa->kelas,
                'sekolah' => $siswa->sekolah->nama ?? '',
                'rowKey' => (string)$siswa->id,
            ];
        });
        return response()->json($siswas);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'nama' => 'required|string',
            'nis' => 'required|string|unique:siswas',
            'jk' => 'required|string',
            'kelas' => 'required|string',
            'sekolah_id' => 'required|exists:sekolahs,id',
        ]);

        $siswa = Siswa::create($validated);
        return response()->json(['status' => 'success', 'message' => 'Siswa ditambahkan', 'data' => $siswa]);
    }

    public function update(Request $request, Siswa $siswa)
    {
        $validated = $request->validate([
            'nama' => 'sometimes|required|string',
            'nis' => 'sometimes|required|string|unique:siswas,nis,' . $siswa->id,
            'jk' => 'sometimes|required|string',
            'kelas' => 'sometimes|required|string',
            'sekolah_id' => 'sometimes|required|exists:sekolahs,id',
        ]);

        $siswa->update($validated);
        return response()->json(['status' => 'success', 'message' => 'Siswa diperbarui', 'data' => $siswa]);
    }

    public function destroy(Siswa $siswa)
    {
        $siswa->delete();
        return response()->json(['status' => 'success', 'message' => 'Siswa dihapus']);
    }

    public function getKelas(Request $request)
    {
        $sekolahId = $request->query('sekolah_id');
        $query = Siswa::query();
        if ($sekolahId) {
            $query->where('sekolah_id', $sekolahId);
        }
        $kelas = $query->distinct()->pluck('kelas');
        return response()->json($kelas);
    }
}
