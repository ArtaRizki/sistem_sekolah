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
    if (name === "Siswa") sheet.appendRow(["Nama", "NIS", "JK", "Kelas", "Sekolah"]);
    if (name === "Mapel") {
      sheet.appendRow(["Nama", "Kode"]);
      sheet.appendRow(["PJOK", "PJOK"]);
      sheet.appendRow(["TIK", "TIK"]);
    }
    if (name === "Sekolah") {
      sheet.appendRow(["Nama", "Alamat"]);
      sheet.appendRow(["MTs Al-Ma'arif 1 Plered", "Plered, Purwakarta"]);
      sheet.appendRow(["MA Al-Ma'arif 2 Plered", "Plered, Purwakarta"]);
      sheet.appendRow(["MAU Al-Azhar 1 Purwakarta", "Purwakarta, Jawa Barat"]);
    }
    if (name === "Nilai") sheet.appendRow(["Nama", "NIS", "Mapel", "Nilai", "Sekolah"]);
    if (name === "Wajah") sheet.appendRow(["ID", "Embedding", "CreatedAt"]);
    if (name === "Absensi") sheet.appendRow(["Tanggal", "Nama", "Status", "Similarity", "Device_Timestamp", "Sekolah"]);
  } else {
    // Auto-migrate: add 'Sekolah' column if missing on relational sheets
    var needsSekolah = ["Guru", "Siswa", "Nilai", "Absensi"];
    if (needsSekolah.indexOf(name) !== -1) {
      var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
      var hasSekolah = false;
      for (var h = 0; h < headers.length; h++) {
        if (headers[h].toString() === "Sekolah") { hasSekolah = true; break; }
      }
      if (!hasSekolah) {
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
    else if (action === "getNilai") result = getNilaiData(e.parameter.mapel, sekolah);
    else if (action === "getRekap") result = getRekapData(e.parameter.bulan, sekolah);
    else if (action === "getRegisteredFace") result = getRegisteredFaceData(e.parameter.id);
    else if (action === "getKelas") result = getKelasData(sekolah);
    
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
  var result = { status: "error", message: "Action not found" };

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
      sheet.appendRow([data.nama, data.nis, data.jk, data.kelas, data.sekolah]);
      result = { status: "success", message: "Siswa ditambahkan" };
    }
    else if (action === "updateSiswa") {
      result = updateRowByKey("Siswa", data.rowKey, [data.nama, data.nis, data.jk, data.kelas, data.sekolah]);
    }
    else if (action === "deleteSiswa") {
      result = deleteRowByKey("Siswa", data.rowKey);
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
      sheet.appendRow([data.nama, data.alamat]);
      result = { status: "success", message: "Sekolah ditambahkan" };
    }
    else if (action === "updateSekolah") {
      result = updateRow("Sekolah", data.oldNama, [data.nama, data.alamat]);
    }
    else if (action === "deleteSekolah") {
      result = deleteRow("Sekolah", data.nama);
    }

    // ---- NILAI CRUD (with Sekolah) ----
    else if (action === "addNilai") {
      var sheet = getSheet("Nilai");
      sheet.appendRow([data.nama, data.nis, data.mapel, data.nilai, data.sekolah]);
      result = { status: "success", message: "Nilai ditambahkan" };
    }
    else if (action === "updateNilai") {
      result = updateRowByKey("Nilai", data.rowKey, [data.nama, data.nis, data.mapel, data.nilai, data.sekolah]);
    }
    else if (action === "deleteNilai") {
      result = deleteRowByKey("Nilai", data.rowKey);
    }

    // ---- FACE & ATTENDANCE ----
    else if (action === "registerFace") {
      var sheet = getSheet("Wajah");
      var userId = data.id || new Date().getTime().toString();
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
    else if (action === "submitAttendance") {
      var sheet = getSheet("Absensi");
      sheet.appendRow([
        new Date().toISOString(),
        data.nama || "Unknown",
        data.status || "Hadir",
        data.similarity || 0,
        data.timestamp || "",
        data.sekolah || ""
      ]);
      result = { status: "success", message: "Attendance recorded" };
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
 * Update by composite rowKey (e.g. "nama|sekolah" or "nis|mapel|sekolah")
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
  return {
    appName: "DRP Absensi",
    guru: "Dheri Rama Permadhi, S.Pd",
    sekolah: getSekolahData(),
    mapel: getMapelData(),
    totalSiswa: countFiltered("Siswa", sekolah),
    totalGuru: countFiltered("Guru", sekolah),
    totalSekolah: getCount("Sekolah"),
    totalMapel: getCount("Mapel")
  };
}

function getCount(sheetName) {
  var sheet = getSs().getSheetByName(sheetName);
  if (!sheet) return 0;
  return Math.max(0, sheet.getLastRow() - 1);
}

/** Count rows filtered by sekolah (last column) */
function countFiltered(sheetName, sekolah) {
  if (!sekolah) return getCount(sheetName);
  var sheet = getSs().getSheetByName(sheetName);
  if (!sheet) return 0;
  var values = sheet.getDataRange().getValues();
  var count = 0;
  var lastCol = values[0].length - 1; // Sekolah is last column
  for (var i = 1; i < values.length; i++) {
    if (values[i][lastCol].toString() === sekolah) count++;
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
      nis: values[i][1].toString(),
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
      data.push({ nama: values[i][0], kode: values[i][1] });
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
      data.push({ nama: values[i][0], alamat: values[i][1] });
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

function getNilaiData(mapel, sekolah) {
  var sheet = getSheet("Nilai");
  var values = sheet.getDataRange().getValues();
  var data = [];
  for (var i = 1; i < values.length; i++) {
    if (!values[i][0]) continue;
    // Col 4 = Sekolah
    if (sekolah && values[i][4].toString() !== sekolah) continue;
    if (mapel && values[i][2].toString() !== mapel) continue;
    data.push({
      nama: values[i][0],
      nis: values[i][1].toString(),
      mapel: values[i][2],
      nilai: values[i][3],
      sekolah: values[i][4],
      rowKey: values[i].map(function(c) { return c.toString(); }).join("|")
    });
  }
  return data;
}

function getRekapData(bulan, sekolah) {
  var sheet = getSheet("Absensi");
  var values = sheet.getDataRange().getValues();
  var rekap = {};
  
  for (var i = 1; i < values.length; i++) {
    var tanggal = values[i][0].toString();
    var nama = values[i][1];
    var status = values[i][2];
    var absenSekolah = values[i][5] || "";
    
    if (sekolah && absenSekolah.toString() !== sekolah) continue;
    if (bulan && tanggal.indexOf(bulan) === -1) continue;
    
    if (!rekap[nama]) rekap[nama] = { nama: nama, hadir: 0, izin: 0, sakit: 0, alpa: 0, total: 0, sekolah: absenSekolah };
    rekap[nama].total++;
    
    if (status === "Hadir") rekap[nama].hadir++;
    else if (status === "Izin") rekap[nama].izin++;
    else if (status === "Sakit") rekap[nama].sakit++;
    else rekap[nama].alpa++;
  }
  
  var result = [];
  for (var key in rekap) {
    var r = rekap[key];
    r.persen = r.total > 0 ? Math.round((r.hadir / r.total) * 100) : 0;
    result.push(r);
  }
  return result;
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
