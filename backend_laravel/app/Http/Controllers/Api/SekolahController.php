<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Sekolah;
use Illuminate\Http\Request;

class SekolahController extends Controller
{
    public function index()
    {
        return response()->json(Sekolah::all());
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'nama' => 'required|string|unique:sekolahs',
            'alamat' => 'required|string',
            'tingkat' => 'required|string',
        ]);

        $sekolah = Sekolah::create($validated);
        return response()->json(['status' => 'success', 'message' => 'Sekolah ditambahkan', 'data' => $sekolah]);
    }

    public function show(Sekolah $sekolah)
    {
        return response()->json($sekolah);
    }

    public function update(Request $request, Sekolah $sekolah)
    {
        $validated = $request->validate([
            'nama' => 'sometimes|required|string|unique:sekolahs,nama,' . $sekolah->id,
            'alamat' => 'sometimes|required|string',
            'tingkat' => 'sometimes|required|string',
        ]);

        $sekolah->update($validated);
        return response()->json(['status' => 'success', 'message' => 'Sekolah diperbarui', 'data' => $sekolah]);
    }

    public function destroy(Sekolah $sekolah)
    {
        $sekolah->delete();
        return response()->json(['status' => 'success', 'message' => 'Sekolah dihapus']);
    }
}
