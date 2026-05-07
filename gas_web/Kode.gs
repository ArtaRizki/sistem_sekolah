function doGet(e) {
  // If request asks for JSON data
  if (e.parameter.action) {
    var action = e.parameter.action;
    var result = {};
    
    if (action === "getDashboard") result = getDashboardData();
    else if (action === "getGuru") result = getGuruData();
    else if (action === "getSiswa") result = getSiswaData(e.parameter.kelas);
    else if (action === "getNilai") result = getNilaiData(e.parameter.mapel);
    else if (action === "getRekap") result = getRekapData(e.parameter.bulan);
    else if (action === "getRegisteredFace") result = getRegisteredFaceData(e.parameter.id);
    
    return ContentService.createTextOutput(JSON.stringify(result))
      .setMimeType(ContentService.MimeType.JSON);
  }

  // Default: Return Web Dashboard
  var template = HtmlService.createTemplateFromFile("Index");
  return template
    .evaluate()
    .setTitle("Sistem Sekolah - Dashboard")
    .addMetaTag("viewport", "width=device-width, initial-scale=1")
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

function doPost(e) {
  var data = JSON.parse(e.postData.contents);
  var action = data.action;
  var result = { status: "error", message: "Action not found" };

  if (action === "registerFace") {
    // In a real scenario, save to a Sheet
    // For now, we simulate success
    result = { status: "success", message: "Face registered successfully" };
  } else if (action === "submitAttendance") {
    result = { status: "success", message: "Attendance recorded" };
  }

  return ContentService.createTextOutput(JSON.stringify(result))
    .setMimeType(ContentService.MimeType.JSON);
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

// ==========================================
// DATA FUNCTIONS
// ==========================================

function getDashboardData() {
  return {
    sekolah: "SDIT AL-FAHMI PALU",
    alamat: "Jl. Pendidikan No. 1, Palu, Sulawesi Tengah",
    totalSiswa: 450,
    totalGuru: 35,
    totalKelas: 18
  };
}

function getGuruData() {
  return [
    { nama: 'Budi Santoso, S.Pd', nip: '198001012005011001', mapel: 'Matematika' },
    { nama: 'Siti Aminah, S.Ag', nip: '198205122008012003', mapel: 'Pend. Agama Islam' },
    { nama: 'Ahmad Fauzi, M.Pd', nip: '197508172000031002', mapel: 'Bahasa Indonesia' },
    { nama: 'Rina Wati, S.Pd', nip: '198811222010012005', mapel: 'Ilmu Pengetahuan Alam' }
  ];
}

function getSiswaData(kelas) {
  var allSiswa = {
    'Kelas 1A': [
      { nama: 'Andi Susanto', nis: '2023001', jk: 'L' },
      { nama: 'Budi Setiawan', nis: '2023002', jk: 'L' },
      { nama: 'Citra Kirana', nis: '2023003', jk: 'P' }
    ],
    'Kelas 1B': [
      { nama: 'Deni Ramadhan', nis: '2023004', jk: 'L' },
      { nama: 'Eka Putri', nis: '2023005', jk: 'P' }
    ]
  };
  return allSiswa[kelas] || [];
}

function getNilaiData(mapel) {
  return [
    { nama: 'Andi Susanto', tugas1: 85, tugas2: 90, uh: 88 },
    { nama: 'Budi Setiawan', tugas1: 75, tugas2: 80, uh: 78 },
    { nama: 'Citra Kirana', tugas1: 95, tugas2: 92, uh: 96 }
  ];
}

function getRekapData(bulan) {
  return [
    { kelas: 'Kelas 1A', hadir: 95, izin: 3, sakit: 2, alpa: 0 },
    { kelas: 'Kelas 1B', hadir: 92, izin: 5, sakit: 2, alpa: 1 },
    { kelas: 'Kelas 2A', hadir: 98, izin: 1, sakit: 1, alpa: 0 }
  ];
}

function getRegisteredFaceData(id) {
  // Mockup: return an empty list or some data if found
  return null; 
}
