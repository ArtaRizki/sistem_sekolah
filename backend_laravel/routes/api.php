<?php

use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\GradeController;
use App\Http\Controllers\Api\MapelController;
use App\Http\Controllers\Api\SekolahController;
use App\Http\Controllers\Api\StudentController;
use App\Http\Controllers\Api\TeacherController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');

// Dashboard
Route::get('/dashboard', [DashboardController::class, 'index']);

// CRUD Resources
Route::apiResource('sekolahs', SekolahController::class);
Route::apiResource('gurus', TeacherController::class);
Route::apiResource('siswas', StudentController::class);
Route::apiResource('mapels', MapelController::class);
Route::apiResource('nilais', GradeController::class);

// Student Extras
Route::get('/kelas', [StudentController::class, 'getKelas']);

// Attendance & Faces
Route::post('/faces/register', [AttendanceController::class, 'registerFace']);
Route::get('/faces/registered', [AttendanceController::class, 'getSiswaWajah']);
Route::post('/attendance/submit', [AttendanceController::class, 'submitAttendance']);
Route::get('/attendance/rekap', [AttendanceController::class, 'getRekap']);
