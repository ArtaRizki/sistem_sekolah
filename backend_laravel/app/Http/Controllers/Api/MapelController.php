<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Mapel;
use Illuminate\Http\Request;

class MapelController extends Controller
{
    public function index(Request $request)
    {
        $sekolahId = $request->query('sekolah_id');
        $query = Mapel::query();
        if ($sekolahId) {
            $query->where(function($q) use ($sekolahId) {
                $q->where('sekolah_id', $sekolahId)->orWhereNull('sekolah_id');
            });
        }
        return response()->json($query->get());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'nama' => 'required|string',
            'kode' => 'required|string',
            'sekolah_id' => 'nullable|exists:sekolahs,id',
        ]);

        $mapel = Mapel::create($validated);
        return response()->json(['status' => 'success', 'message' => 'Mapel ditambahkan', 'data' => $mapel]);
    }

    public function update(Request $request, Mapel $mapel)
    {
        $validated = $request->validate([
            'nama' => 'sometimes|required|string',
            'kode' => 'sometimes|required|string',
            'sekolah_id' => 'nullable|exists:sekolahs,id',
        ]);

        $mapel->update($validated);
        return response()->json(['status' => 'success', 'message' => 'Mapel diperbarui', 'data' => $mapel]);
    }

    public function destroy(Mapel $mapel)
    {
        $mapel->delete();
        return response()->json(['status' => 'success', 'message' => 'Mapel dihapus']);
    }
}
