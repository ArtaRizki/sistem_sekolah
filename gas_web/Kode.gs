// ID SPREADSHEET USER
var SPREADSHEET_ID = "1wydhxdPM_GBtvaPxuR6s-zct463x_8aXYMbBE6pOT_Q";
var _ss = null;

/**
 * Lazy load spreadsheet object to keep the script "lightweight"
 */
function getSs() {
  if (!_ss) _ss = SpreadsheetApp.openById(SPREADSHEET_ID);
  return _ss;
}

/**
 * Helper to get sheet and handle missing sheets
 */
function getSheet(name) {
  var ss = getSs();
  var sheet = ss.getSheetByName(name);
  if (!sheet) {
    sheet = ss.insertSheet(name);
    // Add default headers if needed
    if (name === "Wajah") sheet.appendRow(["ID", "Embedding", "CreatedAt"]);
    if (name === "Absensi") sheet.appendRow(["Tanggal", "Nama", "Status", "Similarity", "Device_Timestamp"]);
  }
  return sheet;
}

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
      var sheet = getSheet("Wajah");
      var userId = data.id || new Date().getTime().toString();
      
      // Check for existing ID to update instead of append
      var finder = sheet.createTextFinder(userId).matchEntireCell(true).findNext();
      var embeddingStr = JSON.stringify(data.embedding);
      
      if (finder) {
        var row = finder.getRow();
        sheet.getRange(row, 2).setValue(embeddingStr); // Update embedding
        sheet.getRange(row, 3).setValue(new Date().toISOString()); // Update timestamp
      } else {
        sheet.appendRow([
          userId, 
          embeddingStr,
          new Date().toISOString()
        ]);
      }
      result = { status: "success", message: "Face registered successfully", id: userId };
    } catch (err) {
      result = { status: "error", message: err.toString() };
    }
  } else if (action === "submitAttendance") {
    try {
      var sheet = getSheet("Absensi");
      
      sheet.appendRow([
        new Date().toISOString(),
        data.nama || "Unknown User", 
        data.status || "Hadir",
        data.similarity || 0,
        data.timestamp || ""
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
  var sheet = getSs().getSheetByName(sheetName);
  if (!sheet) return 0;
  return Math.max(0, sheet.getLastRow() - 1);
}

function getGuruData() {
  var sheet = getSs().getSheetByName("Guru");
  if (!sheet) return [];
  var values = sheet.getDataRange().getValues();
  var data = [];
  for (var i = 1; i < values.length; i++) {
    if (values[i][0]) { // Only if Nama exists
      data.push({
        nama: values[i][0],
        nip: values[i][1],
        mapel: values[i][2]
      });
    }
  }
  return data;
}

function getSiswaData(kelas) {
  var sheet = getSs().getSheetByName("Siswa");
  if (!sheet) return [];
  var values = sheet.getDataRange().getValues();
  var data = [];
  for (var i = 1; i < values.length; i++) {
    if (values[i][0] && (!kelas || values[i][3] === kelas)) {
      data.push({
        nama: values[i][0],
        nis: values[i][1],
        jk: values[i][2],
        kelas: values[i][3]
      });
    }
  }
  return data;
}

function getNilaiData(mapel) {
  var sheet = getSs().getSheetByName("Nilai");
  if (!sheet) return [];
  var values = sheet.getDataRange().getValues();
  var data = [];
  for (var i = 1; i < values.length; i++) {
    if (!mapel || values[i][2] === mapel) {
       data.push({ nama: values[i][0], nis: values[i][1], mapel: values[i][2], nilai: values[i][3] });
    }
  }
  return data.length > 0 ? data : [{ nama: 'Data Kosong', nis: '-', mapel: mapel, nilai: 0 }];
}

function getRekapData(bulan) {
  var sheet = getSs().getSheetByName("Absensi");
  if (!sheet) return [];
  // Basic rekap logic: count appearances in Absensi
  return [{ kelas: 'Total', hadir: getCount("Absensi"), izin: 0, sakit: 0, alpa: 0 }];
}

function getRegisteredFaceData(id) {
  if (!id) return null;
  var sheet = getSheet("Wajah");
  var finder = sheet.createTextFinder(id).matchEntireCell(true).findNext();
  if (finder) {
    var row = finder.getRow();
    var values = sheet.getRange(row, 1, 1, 2).getValues()[0];
    return {
      id: values[0],
      embedding: JSON.parse(values[1])
    };
  }
  return null;
}
