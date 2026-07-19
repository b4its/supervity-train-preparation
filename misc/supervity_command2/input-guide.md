# Command2 Input Guide

Gunakan panduan ini saat menjalankan Saved Operator secara manual di Supervity. Untuk alur normal, jalankan Operator 03 saja; Operator 03 meneruskan output Operator 01 ke Operator 02 secara otomatis.

## Shared Dummy Source File

Sebelum menjalankan Operator 01 atau Operator 03, upload file berikut sebagai `<DROPBOX_ROOT_PATH>/incoming/supplier-evidence.json`.

```json
{
  "notice_id": "DEMO-5000",
  "supplier_id": "3022 ",
  "item_number": " sku-el-440",
  "notice_type": "QUALITY HOLD",
  "received_at": "19/07/2026",
  "po_line_id": "90005-1",
  "line_total": "29,197.41",
  "on_hand_qty": "811 units",
  "safety_stock": "354",
  "comment": "QA hold pending inspection; source retained unchanged."
}
```

Operator 01 otomatis menghasilkan `case_key` dari `notice_id`. Untuk data ini, hasilnya adalah `DEMO-5000` dan folder casenya adalah `cases/CASE-DEMO-5000/`.

## Operator 01: Dropbox Raw JSON Ingestion

Pastikan source file sudah berada di folder `incoming/`. Jangan isi atau membuat `case_key`; tidak ada field tersebut di input Operator 01.

```json
{
  "raw_notice_text": "NOTICE_ID: DEMO-5000\nRECEIVED: 2026-07-19 10:30\nSUPPLIER_ID: 3022\nITEM: SKU-EL-440\nTYPE: quality_hold\nMESSAGE: QA hold on inbound SKU-EL-440 pending inspection.",
  "received_at": "2026-07-19T10:30:00+08:00",
  "trigger_type": "manual"
}
```

Minimal input jika semua informasi sudah ada di file JSON:

```json
{
  "raw_notice_text": "",
  "received_at": "",
  "trigger_type": "manual"
}
```

Hasil yang dipakai Operator 02: `case_key`, `notice`, `dropbox_case_path`, `dropbox_input_path`, `dropbox_output_path`, dan `raw_import_ids`.

## Operator 02: Severity Data Cleaner

Jalankan manual hanya setelah Operator 01 memiliki status `IMPORTED`. Salin nilai dari output Operator 01. Dummy berikut mengasumsikan raw import pertama memiliki ID `1`; ganti `1` dengan ID aktual pada output Operator 01/Supabase.

```json
{
  "case_key": "DEMO-5000",
  "notice": {
    "supplier_id": "3022 ",
    "item_number": " sku-el-440",
    "notice_type": "QUALITY HOLD",
    "received_at_raw": "19/07/2026"
  },
  "dropbox_case_path": "cases/CASE-DEMO-5000",
  "dropbox_input_path": "cases/CASE-DEMO-5000/input",
  "dropbox_output_path": "cases/CASE-DEMO-5000/output",
  "raw_import_ids": [1]
}
```

Jangan menjalankan Operator 02 dengan `raw_import_ids` kosong. Operator akan mengembalikan `RAW_SOURCE_REQUIRED` apabila record raw belum ada.

## Operator 03: Supervity Command 2 Orchestrator

Ini adalah input yang direkomendasikan untuk menjalankan alur end-to-end. Upload dulu source file ke `incoming/`, lalu jalankan input berikut. Anda tidak mengisi `case_key` atau `raw_import_ids`; keduanya dihasilkan dan diteruskan otomatis.

```json
{
  "raw_notice_text": "NOTICE_ID: DEMO-5000\nRECEIVED: 2026-07-19 10:30\nSUPPLIER_ID: 3022\nITEM: SKU-EL-440\nTYPE: quality_hold\nMESSAGE: QA hold on inbound SKU-EL-440 pending inspection.",
  "received_at": "2026-07-19T10:30:00+08:00",
  "trigger_type": "manual"
}
```

Jika file belum ada di `incoming/`, Operator 03 mengembalikan `WAITING_FOR_SOURCE_UPLOAD`. Upload file lalu jalankan Operator 03 lagi. Operator 01 tidak mengimpor duplikat berdasarkan `case_key` dan path file sumber.

## Field Reference

| Field | Isi | Diisi oleh |
|---|---|---|
| `raw_notice_text` | Teks notifikasi tambahan, atau string kosong bila file JSON sudah lengkap | User/trigger |
| `received_at` | Timestamp ISO 8601, atau string kosong bila sudah ada di JSON | User/trigger |
| `trigger_type` | `manual` untuk test UI, `outlook` untuk trigger email Outlook | User/trigger |
| `case_key` | Jangan isi di Operator 01; gunakan output Operator 01 bila Operator 02 dijalankan manual | Operator 01 |
| `raw_import_ids` | Jangan isi di Operator 01/03; gunakan output Operator 01 bila Operator 02 dijalankan manual | Operator 01 |
