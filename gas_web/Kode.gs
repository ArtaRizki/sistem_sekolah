// ID SPREADSHEET USER
var SPREADSHEET_ID = "1wydhxdPM_GBtvaPxuR6s-zct463x_8aXYMbBE6pOT_Q";
var _ss = null;

function getSs() {
  if (!_ss) _ss = SpreadsheetApp.openById(SPREADSHEET_ID);
  return _ss;
}

/**
 * Helper to get or create sheet with default headers & seed data
 * Relational: Guru, Siswa, Nilai, Absensi all have 'Sekolah' column
 * Auto-migrates existing sheets to add 'Sekolah' column if missing
 */
function getSheet(name) {
  var ss = getSs();
  var sheet = ss.getSheetByName(name);
  if (!sheet) {
    sheet = ss.insertSheet(name);
    if (name === "Guru") {
      sheet.appendRow(["Nama", "NIP", "Mapel", "Sekolah"]);
      sheet.appendRow(["Dheri Rama Permadhi, S.Pd", "198706152010121001", "PJOK", "MTs Al-Ma'arif 1 Plered"]);
      sheet.appendRow(["Dheri Rama Permadhi, S.Pd", "198706152010121001", "TIK", "MA Al-Ma'arif 2 Plered"]);
      sheet.appendRow(["Dheri Rama Permadhi, S.Pd", "198706152010121001", "PJOK", "MAU Al-Azhar 1 Purwakarta"]);
    }
    if (name === "Siswa") sheet.appendRow(["Nama", "ID", "JK", "Kelas", "Sekolah"]);
    if (name === "Mapel") {
      sheet.appendRow(["Nama", "Kode", "Sekolah"]);
      sheet.appendRow(["PJOK", "PJOK", "Semua"]);
      sheet.appendRow(["TIK", "TIK", "Semua"]);
    }
    if (name === "Sekolah") {
      sheet.appendRow(["Nama", "Alamat", "Tingkat"]);
      sheet.appendRow(["MTs Al-Ma'arif 1 Plered", "Plered, Purwakarta", "MTS"]);
      sheet.appendRow(["MA Al-Ma'arif 2 Plered", "Plered, Purwakarta", "MA"]);
      sheet.appendRow(["MAU Al-Azhar 1 Purwakarta", "Purwakarta, Jawa Barat", "MA"]);
    }
    if (name === "Nilai") sheet.appendRow(["Nama", "ID", "Mapel", "Nilai", "Sekolah", "Tanggal"]);
    if (name === "Wajah") sheet.appendRow(["ID", "Embedding", "CreatedAt"]);
    if (name === "Absensi") sheet.appendRow(["Tanggal", "Nama", "Status", "Similarity", "Device_Timestamp", "Sekolah"]);
  } else {
    // Auto-migrate: check for missing columns
    var headers = sheet.getRange(1, 1, 1, Math.max(1, sheet.getLastColumn())).getValues()[0];
    
    // 1. Check for 'Tingkat' in Sekolah sheet
    if (name === "Sekolah" && headers.indexOf("Tingkat") === -1) {
      sheet.getRange(1, sheet.getLastColumn() + 1).setValue("Tingkat");
    }
    
    // 2. Check for 'Sekolah' in relational sheets
    var needsSekolah = ["Guru", "Siswa", "Mapel", "Nilai", "Absensi"];
    if (needsSekolah.indexOf(name) !== -1 && headers.indexOf("Sekolah") === -1) {
      var newCol = sheet.getLastColumn() + 1;
      sheet.getRange(1, newCol).setValue("Sekolah");
      // Fill empty sekolah for existing data rows
      var lastRow = sheet.getLastRow();
      if (lastRow > 1) {
        var emptyVals = [];
        for (var r = 0; r < lastRow - 1; r++) emptyVals.push([""]);
        sheet.getRange(2, newCol, lastRow - 1, 1).setValues(emptyVals);
      }
    }
    
    // 3. Check for 'Tanggal' in Nilai sheet
    if (name === "Nilai" && headers.indexOf("Tanggal") === -1) {
      var tglCol = sheet.getLastColumn() + 1;
      sheet.getRange(1, tglCol).setValue("Tanggal");
      var lastRowTgl = sheet.getLastRow();
      if (lastRowTgl > 1) {
        var emptyTgl = [];
        for (var r = 0; r < lastRowTgl - 1; r++) emptyTgl.push([""]);
        sheet.getRange(2, tglCol, lastRowTgl - 1, 1).setValues(emptyTgl);
      }
    }
  }
  return sheet;
}

// ==========================================
// doGet - READ operations + Web Dashboard
// ==========================================
function doGet(e) {
  if (e.parameter.action) {
    var action = e.parameter.action;
    var sekolah = e.parameter.sekolah || "";
    var result = {};
    
    if (action === "getDashboard") result = getDashboardData(sekolah);
    else if (action === "getGuru") result = getGuruData(sekolah);
    else if (action === "getSiswa") result = getSiswaData(e.parameter.kelas, sekolah);
    else if (action === "getMapel") result = getMapelData();
    else if (action === "getSekolah") result = getSekolahData();
    else if (action === "getNilai") result = getNilaiData(e.parameter.mapel, sekolah, e.parameter.tanggal || "");
    else if (action === "getRekap") result = getRekapData(e.parameter.bulan, sekolah, e.parameter.kelas);
    else if (action === "getRegisteredFace") result = getRegisteredFaceData(e.parameter.id);
    else if (action === "getKelas") result = getKelasData(sekolah);
    else if (action === "getSiswaWajah") result = getSiswaWajahData(sekolah);
    
    return ContentService.createTextOutput(JSON.stringify(result))
      .setMimeType(ContentService.MimeType.JSON);
  }

  var template = HtmlService.createTemplateFromFile("Index");
  return template
    .evaluate()
    .setTitle("DRP Absensi - Dashboard")
    .addMetaTag("viewport", "width=device-width, initial-scale=1")
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

// ==========================================
// doPost - CREATE / UPDATE / DELETE
// ==========================================
function doPost(e) {
  var data = JSON.parse(e.postData.contents);
  var action = data.action;
  var result = { status: "error", message: "Action not found: " + String(action) };

  try {
    // ---- GURU CRUD (with Sekolah) ----
    if (action === "addGuru") {
      var sheet = getSheet("Guru");
      sheet.appendRow([data.nama, data.nip, data.mapel, data.sekolah]);
      result = { status: "success", message: "Guru ditambahkan" };
    }
    else if (action === "updateGuru") {
      result = updateRowByKey("Guru", data.rowKey, [data.nama, data.nip, data.mapel, data.sekolah]);
    }
    else if (action === "deleteGuru") {
      result = deleteRowByKey("Guru", data.rowKey);
    }

    // ---- SISWA CRUD (with Sekolah) ----
    else if (action === "addSiswa") {
      var sheet = getSheet("Siswa");
      // Auto-increment ID
      var values = sheet.getDataRange().getValues();
      var maxId = 0;
      for (var i = 1; i < values.length; i++) {
        var idVal = parseInt(values[i][1]) || 0;
        if (idVal > maxId) maxId = idVal;
      }
      var newId = maxId + 1;
      sheet.appendRow([data.nama, newId, data.jk, data.kelas, data.sekolah]);
      result = { status: "success", message: "Siswa ditambahkan" };
    }
    else if (action === "updateSiswa") {
      // Preserve existing ID when updating
      var sheet = getSheet("Siswa");
      var values = sheet.getDataRange().getValues();
      var found = false;
      for (var i = 1; i < values.length; i++) {
        var key = values[i].map(function(c) { return c.toString(); }).join("|");
        if (key === data.rowKey) {
          var existingId = values[i][1]; // Preserve existing ID
          sheet.getRange(i + 1, 1, 1, 5).setValues([[data.nama, existingId, data.jk, data.kelas, data.sekolah]]);
          found = true;
          break;
        }
      }
      result = found ? { status: "success", message: "Siswa diperbarui" } : { status: "error", message: "Data tidak ditemukan" };
    }
    else if (action === "deleteSiswa") {
      var rowParts = data.rowKey.split("|");
      var namaSiswa = rowParts[0];
      var idSiswa = rowParts[1];
      
      result = deleteRowByKey("Siswa", data.rowKey);
      
      if (result.status === "success") {
        // Cascade delete Wajah
        if (idSiswa) {
           var wSheet = getSheet("Wajah");
           var wValues = wSheet.getDataRange().getValues();
           for (var w = wValues.length - 1; w >= 1; w--) {
              if (wValues[w][0].toString() === idSiswa) {
               wSheet.deleteRow(w + 1);
             }
           }
           
           // Cascade delete Nilai (ID is col 2 / index 1)
            var nSheet = getSheet("Nilai");
            var nValues = nSheet.getDataRange().getValues();
            for (var n = nValues.length - 1; n >= 1; n--) {
              if (nValues[n][1].toString() === idSiswa) {
                nSheet.deleteRow(n + 1);
             }
           }
        }
        
        // Cascade delete Absensi (Nama is col 2 / index 1)
        if (namaSiswa) {
           var aSheet = getSheet("Absensi");
           var aValues = aSheet.getDataRange().getValues();
           for (var a = aValues.length - 1; a >= 1; a--) {
             if (aValues[a][1].toString() === namaSiswa) {
               aSheet.deleteRow(a + 1);
             }
           }
        }
      }
    }

    // ---- MAPEL CRUD (with Sekolah assignment) ----
    else if (action === "addMapel") {
      var sheet = getSheet("Mapel");
      sheet.appendRow([data.nama, data.kode, data.sekolah || "Semua"]);
      result = { status: "success", message: "Mapel ditambahkan" };
    }
    else if (action === "updateMapel") {
      result = updateRow("Mapel", data.oldNama, [data.nama, data.kode, data.sekolah || "Semua"]);
    }
    else if (action === "deleteMapel") {
      result = deleteRow("Mapel", data.nama);
    }

    // ---- SEKOLAH CRUD ----
    else if (action === "addSekolah") {
      var sheet = getSheet("Sekolah");
      sheet.appendRow([data.nama, data.alamat, data.tingkat || "MTS"]);
      result = { status: "success", message: "Sekolah ditambahkan" };
    }
    else if (action === "updateSekolah") {
      result = updateRow("Sekolah", data.oldNama, [data.nama, data.alamat, data.tingkat || "MTS"]);
    }
    else if (action === "deleteSekolah") {
      result = deleteRow("Sekolah", data.nama);
    }

    // ---- NILAI CRUD (with Sekolah + Tanggal) ----
    else if (action === "addNilai") {
      var sheet = getSheet("Nilai");
      var tanggal = data.tanggal || "";
      result = { status: "processing" }; // Reset result to avoid "Action not found" check failure
      
      // Check for duplicate: same ID + Mapel + Tanggal + Sekolah
      if (tanggal) {
        var existing = sheet.getDataRange().getValues();
        for (var d = 1; d < existing.length; d++) {
          var rowId = existing[d][1].toString();
          var rowMapel = existing[d][2].toString();
          var rowSekolah = existing[d][4].toString();
          var rowTanggal = "";
          
          if (existing[d][5]) {
            try {
              if (existing[d][5] instanceof Date) {
                rowTanggal = Utilities.formatDate(existing[d][5], Session.getScriptTimeZone(), "yyyy-MM-dd");
              } else {
                rowTanggal = existing[d][5].toString();
              }
            } catch(e) {
              rowTanggal = existing[d][5].toString();
            }
          }

          if (rowId === data.id.toString() &&
              rowMapel === data.mapel &&
              rowTanggal === tanggal &&
              rowSekolah === data.sekolah) {
            result = { status: "error", message: "Nilai untuk " + data.nama + " pada tanggal " + tanggal + " dengan mapel " + data.mapel + " sudah ada" };
            break;
          }
        }
        
        if (result.status === "error") {
          // Already set duplicate error above, skip append
        } else {
          sheet.appendRow([data.nama, data.id, data.mapel, data.nilai, data.sekolah, tanggal]);
          result = { status: "success", message: "Nilai ditambahkan" };
        }
      } else {
        sheet.appendRow([data.nama, data.id, data.mapel, data.nilai, data.sekolah, tanggal]);
        result = { status: "success", message: "Nilai ditambahkan" };
      }
    }
    else if (action === "updateNilai") {
      result = updateRowByKey("Nilai", data.rowKey, [data.nama, data.id, data.mapel, data.nilai, data.sekolah, data.tanggal || ""]);
    }
    else if (action === "deleteNilai") {
      result = deleteRowByKey("Nilai", data.rowKey);
    }

    // ---- FACE & ATTENDANCE ----
    else if (action === "registerFace") {
      var sheet = getSheet("Wajah");
      var userId = data.id;
      if (!userId) {
         result = { status: "error", message: "ID diperlukan" };
      } else {
        var finder = sheet.createTextFinder(userId).matchEntireCell(true).findNext();
        var embeddingStr = JSON.stringify(data.embedding);
        if (finder) {
          var row = finder.getRow();
          sheet.getRange(row, 2).setValue(embeddingStr);
          sheet.getRange(row, 3).setValue(new Date().toISOString());
        } else {
          sheet.appendRow([userId, embeddingStr, new Date().toISOString()]);
        }
        result = { status: "success", message: "Face registered", id: userId };
      }
    }
    else if (action === "submitAttendance") {
      var sheet = getSheet("Absensi");
      var nama = data.nama || "Unknown";
      var today = new Date();
      var todayStr = today.getFullYear() + "-" + 
        ("0" + (today.getMonth() + 1)).slice(-2) + "-" + 
        ("0" + today.getDate()).slice(-2);
      
      // Check if this student already has attendance today
      var existing = sheet.getDataRange().getValues();
      var alreadyAbsen = false;
      for (var d = 1; d < existing.length; d++) {
        var rowDate = "";
        try {
          var dt = new Date(existing[d][0]);
          rowDate = dt.getFullYear() + "-" + 
            ("0" + (dt.getMonth() + 1)).slice(-2) + "-" + 
            ("0" + dt.getDate()).slice(-2);
        } catch(e) {
          rowDate = existing[d][0].toString().substring(0, 10);
        }
        if (existing[d][1].toString() === nama && rowDate === todayStr) {
          alreadyAbsen = true;
          break;
        }
      }
      
      if (alreadyAbsen) {
        result = { status: "duplicate", message: nama + " sudah absen hari ini" };
      } else {
        sheet.appendRow([
          today.toISOString(),
          nama,
          data.status || "Hadir",
          data.similarity || 0,
          data.timestamp || "",
          data.sekolah || ""
        ]);
        result = { status: "success", message: "Attendance recorded" };
      }
    }
    else if (action === "addManualAbsensi") {
      var sheet = getSheet("Absensi");
      var nama = data.nama || "";
      var statusAbsen = data.status || "Hadir";
      var sekolahAbsen = data.sekolah || "";
      var tanggalInput = data.tanggal || "";
      
      // Parse the date or use today
      var targetDate;
      if (tanggalInput) {
        targetDate = new Date(tanggalInput);
      } else {
        targetDate = new Date();
      }
      var targetDateStr = targetDate.getFullYear() + "-" + 
        ("0" + (targetDate.getMonth() + 1)).slice(-2) + "-" + 
        ("0" + targetDate.getDate()).slice(-2);
      
      // Check duplicate: same name + same date
      var existing = sheet.getDataRange().getValues();
      var alreadyAbsen = false;
      for (var d = 1; d < existing.length; d++) {
        var rowDate = "";
        try {
          var dt = new Date(existing[d][0]);
          rowDate = dt.getFullYear() + "-" + 
            ("0" + (dt.getMonth() + 1)).slice(-2) + "-" + 
            ("0" + dt.getDate()).slice(-2);
        } catch(e) {
          rowDate = existing[d][0].toString().substring(0, 10);
        }
        if (existing[d][1].toString() === nama && rowDate === targetDateStr) {
          alreadyAbsen = true;
          break;
        }
      }
      
      if (alreadyAbsen) {
        result = { status: "duplicate", message: nama + " sudah tercatat absen pada tanggal " + targetDateStr };
      } else {
        sheet.appendRow([
          targetDate.toISOString(),
          nama,
          statusAbsen,
          0,
          "",
          sekolahAbsen
        ]);
        result = { status: "success", message: "Absensi " + statusAbsen + " untuk " + nama + " berhasil dicatat" };
      }
    }
  } catch (err) {
    result = { status: "error", message: err.toString() };
  }

  return ContentService.createTextOutput(JSON.stringify(result))
    .setMimeType(ContentService.MimeType.JSON);
}

// ==========================================
// GENERIC CRUD HELPERS
// ==========================================

/** Update row by first-column match (for Mapel, Sekolah) */
function updateRow(sheetName, searchValue, newValues) {
  var sheet = getSheet(sheetName);
  var values = sheet.getDataRange().getValues();
  for (var i = 1; i < values.length; i++) {
    if (values[i][0].toString() === searchValue) {
      sheet.getRange(i + 1, 1, 1, newValues.length).setValues([newValues]);
      return { status: "success", message: sheetName + " diperbarui" };
    }
  }
  return { status: "error", message: "Data tidak ditemukan" };
}

/** Delete row by first-column match (for Mapel, Sekolah) */
function deleteRow(sheetName, searchValue) {
  var sheet = getSheet(sheetName);
  var values = sheet.getDataRange().getValues();
  for (var i = values.length - 1; i >= 1; i--) {
    if (values[i][0].toString() === searchValue) {
      sheet.deleteRow(i + 1);
      return { status: "success", message: sheetName + " dihapus" };
    }
  }
  return { status: "error", message: "Data tidak ditemukan" };
}

/** 
 * Update by composite rowKey (e.g. "nama|sekolah" or "id|mapel|sekolah")
 * The rowKey is matched against row values joined with "|"
 */
function updateRowByKey(sheetName, rowKey, newValues) {
  var sheet = getSheet(sheetName);
  var values = sheet.getDataRange().getValues();
  for (var i = 1; i < values.length; i++) {
    var key = values[i].map(function(c) { return c.toString(); }).join("|");
    if (key === rowKey) {
      sheet.getRange(i + 1, 1, 1, newValues.length).setValues([newValues]);
      return { status: "success", message: sheetName + " diperbarui" };
    }
  }
  return { status: "error", message: "Data tidak ditemukan" };
}

/** Delete by composite rowKey */
function deleteRowByKey(sheetName, rowKey) {
  var sheet = getSheet(sheetName);
  var values = sheet.getDataRange().getValues();
  for (var i = values.length - 1; i >= 1; i--) {
    var key = values[i].map(function(c) { return c.toString(); }).join("|");
    if (key === rowKey) {
      sheet.deleteRow(i + 1);
      return { status: "success", message: sheetName + " dihapus" };
    }
  }
  return { status: "error", message: "Data tidak ditemukan" };
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

// ==========================================
// READ FUNCTIONS (all filtered by sekolah)
// ==========================================

function getDashboardData(sekolah) {
  var sekolahData = getSekolahData();
  var tingkat = "";
  if (sekolah) {
    for (var i = 0; i < sekolahData.length; i++) {
      if (sekolahData[i].nama === sekolah) {
        tingkat = sekolahData[i].tingkat;
        break;
      }
    }
  }
  
  return {
    appName: "DRP Absensi",
    guru: "Dheri Rama Permadhi, S.Pd",
    sekolah: sekolahData,
    mapel: getMapelData(),
    totalSiswa: countFiltered("Siswa", sekolah),
    totalGuru: countFiltered("Guru", sekolah),
    totalSekolah: sekolahData.length,
    totalMapel: getCount("Mapel"),
    tingkat: tingkat
  };
}

function getCount(sheetName) {
  var sheet = getSs().getSheetByName(sheetName);
  if (!sheet) return 0;
  return Math.max(0, sheet.getLastRow() - 1);
}

/** Count rows filtered by sekolah column (header-aware) */
function countFiltered(sheetName, sekolah) {
  if (!sekolah) return getCount(sheetName);
  var sheet = getSs().getSheetByName(sheetName);
  if (!sheet) return 0;
  var values = sheet.getDataRange().getValues();
  if (values.length < 2) return 0;
  
  var headers = values[0];
  var colIdx = headers.indexOf("Sekolah");
  if (colIdx === -1) return 0;
  
  var count = 0;
  for (var i = 1; i < values.length; i++) {
    if (values[i][colIdx].toString() === sekolah) count++;
  }
  return count;
}

function getGuruData(sekolah) {
  var sheet = getSheet("Guru");
  var values = sheet.getDataRange().getValues();
  var data = [];
  for (var i = 1; i < values.length; i++) {
    if (!values[i][0]) continue;
    // Col 3 = Sekolah
    if (sekolah && values[i][3].toString() !== sekolah) continue;
    data.push({
      nama: values[i][0],
      nip: values[i][1].toString(),
      mapel: values[i][2],
      sekolah: values[i][3],
      rowKey: values[i].map(function(c) { return c.toString(); }).join("|")
    });
  }
  return data;
}

function getSiswaData(kelas, sekolah) {
  var sheet = getSheet("Siswa");
  var values = sheet.getDataRange().getValues();
  var data = [];
  for (var i = 1; i < values.length; i++) {
    if (!values[i][0]) continue;
    // Col 4 = Sekolah
    if (sekolah && values[i][4].toString() !== sekolah) continue;
    if (kelas && values[i][3].toString() !== kelas) continue;
    data.push({
      nama: values[i][0],
      id: values[i][1].toString(),
      jk: values[i][2],
      kelas: values[i][3],
      sekolah: values[i][4],
      rowKey: values[i].map(function(c) { return c.toString(); }).join("|")
    });
  }
  return data;
}

function getMapelData() {
  var sheet = getSheet("Mapel");
  var values = sheet.getDataRange().getValues();
  var data = [];
  for (var i = 1; i < values.length; i++) {
    if (values[i][0]) {
      data.push({ 
        nama: values[i][0], 
        kode: values[i][1],
        sekolah: values[i][2] || "Semua"
      });
    }
  }
  return data;
}

function getSekolahData() {
  var sheet = getSheet("Sekolah");
  var values = sheet.getDataRange().getValues();
  var data = [];
  for (var i = 1; i < values.length; i++) {
    if (values[i][0]) {
      data.push({ 
        nama: values[i][0], 
        alamat: values[i][1], 
        tingkat: values[i][2] || "MTS" 
      });
    }
  }
  return data;
}

function getKelasData(sekolah) {
  var sheet = getSheet("Siswa");
  var values = sheet.getDataRange().getValues();
  var kelasSet = {};
  for (var i = 1; i < values.length; i++) {
    if (sekolah && values[i][4].toString() !== sekolah) continue;
    if (values[i][3]) kelasSet[values[i][3]] = true;
  }
  return Object.keys(kelasSet);
}

function getNilaiData(mapel, sekolah, tanggal) {
  var sheet = getSheet("Nilai");
  var values = sheet.getDataRange().getValues();
  var data = [];
  for (var i = 1; i < values.length; i++) {
    if (!values[i][0]) continue;
    var rowTanggal = "";
    if (values[i][5]) {
      try {
        if (values[i][5] instanceof Date) {
          rowTanggal = Utilities.formatDate(values[i][5], Session.getScriptTimeZone(), "yyyy-MM-dd");
        } else {
          rowTanggal = values[i][5].toString();
        }
      } catch(e) {
        rowTanggal = values[i][5].toString();
      }
    }

    if (sekolah && values[i][4].toString() !== sekolah) continue;
    if (mapel && values[i][2].toString() !== mapel) continue;
    if (tanggal && rowTanggal !== tanggal) continue;

    data.push({
      nama: values[i][0],
      id: values[i][1].toString(),
      mapel: values[i][2],
      nilai: values[i][3],
      sekolah: values[i][4],
      tanggal: rowTanggal,
      rowKey: values[i].map(function(c) { return c.toString(); }).join("|")
    });
  }
  return data;
}

function getRekapData(bulan, sekolah, kelas) {
  var sheet = getSheet("Absensi");
  var values = sheet.getDataRange().getValues();
  var rekap = {};
  var bulanNames = ["Januari", "Februari", "Maret", "April", "Mei", "Juni",
                    "Juli", "Agustus", "September", "Oktober", "November", "Desember"];
                    
  // Inisialisasi data rekap dengan semua siswa yang sesuai filter
  // Agar siswa yang belum absen tetap muncul dengan angka 0
  var sheetSiswa = getSheet("Siswa");
  var valuesSiswa = sheetSiswa.getDataRange().getValues();
  for (var j = 1; j < valuesSiswa.length; j++) {
    var namaSiswa = valuesSiswa[j][0] ? valuesSiswa[j][0].toString().trim() : "";
    var kelasSiswa = valuesSiswa[j][3] ? valuesSiswa[j][3].toString().trim() : "";
    var sekolahSiswa = valuesSiswa[j][4] ? valuesSiswa[j][4].toString().trim() : "";
    
    if (!namaSiswa) continue;
    if (sekolah && sekolahSiswa !== sekolah.trim()) continue;
    if (kelas && kelasSiswa !== kelas.trim()) continue;
    
    rekap[namaSiswa] = { 
      nama: namaSiswa, 
      hadir: 0, 
      izin: 0, 
      sakit: 0, 
      alpa: 0, 
      total: 0, 
      sekolah: sekolahSiswa, 
      kelas: kelasSiswa 
    };
  }
  
  for (var i = 1; i < values.length; i++) {
    var tanggalRaw = values[i][0];
    var nama = values[i][1] ? values[i][1].toString().trim() : "";
    var status = values[i][2];
    
    // Hanya hitung jika siswa ada di daftar rekap (sesuai filter)
    if (!rekap[nama]) continue;
    
    // Parse tanggal
    try {
      var dt = new Date(tanggalRaw);
      var bulanTahun = bulanNames[dt.getMonth()] + " " + dt.getFullYear();
      if (bulanTahun !== bulan) continue;
    } catch(e) {
      continue;
    }
    
    rekap[nama].total++;
    
    if (status === "Hadir") rekap[nama].hadir++;
    else if (status === "Izin") rekap[nama].izin++;
    else if (status === "Sakit") rekap[nama].sakit++;
    else if (status === "Alpa") rekap[nama].alpa++;
  }
  
  var result = [];
  for (var key in rekap) {
    var r = rekap[key];
    r.persen = r.total > 0 ? Math.round((r.hadir / r.total) * 100) : 0;
    result.push(r);
  }
  return result;
}

function getSiswaWajahData(sekolah) {
  var siswaSheet = getSheet("Siswa");
  var wajahSheet = getSheet("Wajah");
  
  var siswaValues = siswaSheet.getDataRange().getValues();
  var wajahValues = wajahSheet.getDataRange().getValues();
  
  var wajahMap = {};
  for (var j = 1; j < wajahValues.length; j++) {
    wajahMap[wajahValues[j][0].toString()] = JSON.parse(wajahValues[j][1]);
  }
  
  var data = [];
  for (var i = 1; i < siswaValues.length; i++) {
    var id = siswaValues[i][1].toString();
    if (!id) continue;
    if (sekolah && siswaValues[i][4].toString() !== sekolah) continue;
    
    if (wajahMap[id]) {
      data.push({
        nama: siswaValues[i][0],
        id: id,
        kelas: siswaValues[i][3],
        sekolah: siswaValues[i][4],
        embedding: wajahMap[id]
      });
    }
  }
  return data;
}

function getRegisteredFaceData(id) {
  if (!id) return null;
  var sheet = getSheet("Wajah");
  var finder = sheet.createTextFinder(id).matchEntireCell(true).findNext();
  if (finder) {
    var row = finder.getRow();
    var values = sheet.getRange(row, 1, 1, 2).getValues()[0];
    return { id: values[0], embedding: JSON.parse(values[1]) };
  }
  return null;
}
