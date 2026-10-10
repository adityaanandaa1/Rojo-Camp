/**
 * Backend Google Apps Script untuk Kebun Rojo Camp.
 *
 * doGet  → halaman Dashboard, atau data JSON jika ?action=getData
 * doPost → menerima sinkronisasi data dari aplikasi Android
 *
 * Setiap perubahan file ini perlu di-deploy ulang sebagai versi baru.
 */

// Harus sama dengan AppConfig.sheetsTabName di aplikasi
var SHEET_NAME = 'Rombongan';

var HEADERS = [
  'id',
  'nama',
  'alamat',
  'tanggal_mulai',
  'tanggal_selesai',
  'jumlah_pengunjung',
  'jenis_pesanan',
  'slot_terpilih_label',
  'slot_terpilih_id',
  'status',
  'waktu_checkout',
  'keterangan',
  'created_at',
  'synced_at'
];

function doGet(e) {
  var action = e && e.parameter ? e.parameter.action : '';

  if (action === 'getData') {
    try {
      return _jsonResponse(_readRecords());
    } catch (err) {
      console.error('doGet error:', err);
      return _jsonResponse({ status: 'error', message: err.toString() });
    }
  }

  return HtmlService.createHtmlOutputFromFile('Dashboard')
    .setTitle('Dashboard Kebun Rojo Camp')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1');
}

function doPost(e) {
  try {
    var records = JSON.parse(e.postData.contents).records;

    if (!Array.isArray(records) || records.length === 0) {
      return _jsonResponse({ status: 'ok', message: 'No records to sync', synced: 0 });
    }

    var sheet = _getSheet();
    _ensureHeaders(sheet);

    var syncedAt = new Date().toISOString();
    var inserted = 0;

    records.forEach(function (record) {
      var row = _toRow(record, syncedAt);
      var rowNum = _findRowById(sheet, record.id);

      if (rowNum > 0) {
        sheet.getRange(rowNum, 1, 1, row.length).setValues([row]);
      } else {
        sheet.appendRow(row);
        inserted++;
      }
    });

    return _jsonResponse({
      status: 'ok',
      synced: records.length,
      inserted: inserted,
      updated: records.length - inserted
    });
  } catch (err) {
    console.error('doPost error:', err);
    return _jsonResponse({ status: 'error', message: err.toString() });
  }
}

// Dipanggil dari Dashboard.html lewat google.script.run
function ambilSemuaData() {
  return JSON.stringify(_readRecords());
}

// ── Helpers ───────────────────────────────────────────────────────

function _getSheet() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  return ss.getSheetByName(SHEET_NAME) || ss.insertSheet(SHEET_NAME);
}

function _ensureHeaders(sheet) {
  if (sheet.getLastRow() > 0) return;

  sheet.appendRow(HEADERS);
  sheet.getRange(1, 1, 1, HEADERS.length)
    .setFontWeight('bold')
    .setBackground('#0088FF')
    .setFontColor('#FFFFFF');
  sheet.setFrozenRows(1);
}

function _readRecords() {
  var data = _getSheet().getDataRange().getValues();
  if (data.length <= 1) return [];

  var headers = data[0];

  return data.slice(1)
    .map(function (row) {
      var obj = {};
      headers.forEach(function (h, i) {
        obj[h] = row[i] instanceof Date ? row[i].toISOString() : row[i];
      });
      return obj;
    })
    .filter(function (obj) { return obj.id; });
}

// Return nomor baris (1-indexed), atau -1 jika tidak ditemukan
function _findRowById(sheet, id) {
  var lastRow = sheet.getLastRow();
  if (lastRow <= 1) return -1;

  var ids = sheet.getRange(2, 1, lastRow - 1, 1).getValues();
  for (var i = 0; i < ids.length; i++) {
    if (ids[i][0] === id) return i + 2;
  }
  return -1;
}

function _toRow(record, syncedAt) {
  var slotIds = Array.isArray(record.slot_terpilih_id)
    ? record.slot_terpilih_id.join(';')
    : record.slot_terpilih_id;

  return [
    record.id || '',
    record.nama || '',
    record.alamat || '',
    record.tanggal_mulai || '',
    record.tanggal_selesai || '',
    record.jumlah_pengunjung || 0,
    record.jenis_pesanan || '',
    record.slot_terpilih_label || '',
    slotIds || '',
    record.status || '',
    record.waktu_checkout || '',
    record.keterangan || '',
    record.created_at || '',
    syncedAt
  ];
}

function _jsonResponse(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
