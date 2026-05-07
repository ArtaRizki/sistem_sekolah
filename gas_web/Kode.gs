// ID SPREADSHEET USER
var SPREADSHEET_ID = "1wydhxdPM_GBtvaPxuR6s-zct463x_8aXYMbBE6pOT_Q";
var ss = SpreadsheetApp.openById(SPREADSHEET_ID);

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
    try {
      var sheet = ss.getSheetByName("Wajah");
      if (!sheet) sheet = ss.insertSheet("Wajah");
      
      // Save ID and Embedding
      sheet.appendRow([
        new Date().getTime().toString(), 
        JSON.stringify(data.embedding),
        new Date().toISOString()
      ]);
      result = { status: "success", message: "Face registered successfully" };
    } catch (err) {
      result = { status: "error", message: err.toString() };
    }
  } else if (action === "submitAttendance") {
    try {
      var sheet = ss.getSheetByName("Absensi");
      if (!sheet) sheet = ss.insertSheet("Absensi");
      
      sheet.appendRow([
        new Date().toISOString(),
        "User Mobile", // Bisa dikembangkan untuk kirim Nama/ID Siswa
        "Hadir",
        data.similarity,
        data.timestamp
      ]);
      result = { status: "success", message: "Attendance recorded" };
    } catch (err) {
      result = { status: "error", message: err.toString() };
    }
  }

  return ContentService.createTextOutput(JSON.stringify(result))
    .setMimeType(ContentService.MimeType.JSON);
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

// ==========================================
// DATA FUNCTIONS (Reading from Spreadsheet)
// ==========================================

function getDashboardData() {
  // Bisa dihitung dari data sheet atau statis sementara
  return {
    sekolah: "SDIT AL-FAHMI PALU",
    alamat: "Jl. Pendidikan No. 1, Palu, Sulawesi Tengah",
    totalSiswa: getCount("Siswa"),
    totalGuru: getCount("Guru"),
    totalKelas: 18
  };
}

function getCount(sheetName) {
  var sheet = ss.getSheetByName(sheetName);
  if (!sheet) return 0;
  return Math.max(0, sheet.getLastRow() - 1);
}

function getGuruData() {
  var sheet = ss.getSheetByName("Guru");
  if (!sheet) return [];
  var values = sheet.getDataRange().getValues();
  var data = [];
  for (var i = 1; i < values.length; i++) {
    data.push({
      nama: values[i][0],
      nip: values[i][1],
      mapel: values[i][2]
    });
  }
  return data;
}

function getSiswaData(kelas) {
  var sheet = ss.getSheetByName("Siswa");
  if (!sheet) return [];
  var values = sheet.getDataRange().getValues();
  var data = [];
  for (var i = 1; i < values.length; i++) {
    if (!kelas || values[i][3] === kelas) {
      data.push({
        nama: values[i][0],
        nis: values[i][1],
        jk: values[i][2]
      });
    }
  }
  return data;
}

function getNilaiData(mapel) {
  // Contoh logic pembacaan nilai
  return [
    { nama: 'Contoh Siswa', tugas1: 85, tugas2: 90, uh: 88 }
  ];
}

function getRekapData(bulan) {
  return [
    { kelas: 'Kelas 1A', hadir: 95, izin: 3, sakit: 2, alpa: 0 }
  ];
}

function getRegisteredFaceData(id) {
  return null;
}
