# Design Specification — Halaman Daftar Pengunjung

## 1. Tujuan

Halaman **Daftar Pengunjung** digunakan untuk menampilkan dua kelompok data pengunjung berdasarkan status:

- **Aktif**
- **Non-Aktif**

Keduanya diperlakukan sebagai dua halaman/tab yang dapat berpindah tanpa meninggalkan halaman daftar pengunjung.

Desain harus mempertahankan kesan bahwa **tab yang sedang aktif menyatu dengan area daftar di bawahnya**. Stroke hitam pada tab pada gambar referensi **tidak digunakan sebagai bagian dari desain final**; stroke tersebut hanya berfungsi sebagai penanda visual pada contoh.

Referensi visual berasal dari desain yang diberikan pengguna. fileciteturn0file0L4-L6

---

## 2. Struktur Halaman

Urutan elemen dari atas ke bawah:

1. Status bar perangkat
2. Judul halaman: **Daftar Pengunjung**
3. Search bar
4. Tab switcher:
   - Aktif
   - Non-Aktif
5. Header tabel:
   - Nama Pengunjung
   - Status
6. Daftar pengunjung sesuai tab yang sedang aktif
7. Bottom navigation:
   - Beranda
   - Tombol tambah (+)
   - Pengunjung

### Struktur visual

```text
┌────────────────────────────────────┐
│                                    │
│          Daftar Pengunjung         │
│                                    │
│  ┌──────────────────────────────┐  │
│  │ 🔍 Cari nama pengunjung...   │  │
│  └──────────────────────────────┘  │
│                                    │
│  ┌────────────────┐┌─────────────┐ │
│  │     AKTIF      ││  NON-AKTIF  │ │
│  └────────────────┴─────────────┘ │
│  ┌────────────────────────────────┐ │
│  │ Nama Pengunjung       Status  │ │
│  ├────────────────────────────────┤ │
│  │ Farizki Radiansyah      Aktif │ │
│  │ Novalino Ricsawan       Aktif │ │
│  │ Nabil Nobel             Aktif │ │
│  │ ...                            │ │
│  └────────────────────────────────┘ │
│                                    │
│       Beranda    +    Pengunjung   │
└────────────────────────────────────┘
```

---

## 3. Sistem Warna Tab + Content

Prinsip utama:

> **Background tab aktif harus sama persis dengan background area daftar.**

Hal ini menciptakan efek visual seolah-olah tab aktif merupakan bagian yang menyatu dengan konten.

### State Aktif

Ketika tab **Aktif** sedang dipilih:

- Tab Aktif: `#FFFFFF`
- Area daftar Aktif: `#FFFFFF`
- Tab Non-Aktif: `#F9F9F9`
- Area Non-Aktif tidak ditampilkan.
- Tidak ada stroke hitam pada Tab Aktif.
- Tab Non-Aktif boleh memiliki pemisah visual yang sangat halus, tetapi jangan menggunakan border hitam.

```text
          TAB AKTIF
       ┌──────────────┐
       │    Aktif     │  ← #FFFFFF
       └──────────────┘
       ┌────────────────────────────┐
       │      AREA DAFTAR            │
       │         #FFFFFF             │
       │                             │
       └────────────────────────────┘

       Tab Non-Aktif
       #F9F9F9
```

### State Non-Aktif

Ketika tab **Non-Aktif** sedang dipilih:

- Tab Non-Aktif: `#FFFFFF`
- Area daftar Non-Aktif: `#FFFFFF`
- Tab Aktif: `#F9F9F9`
- Tidak ada stroke hitam pada Tab Non-Aktif.
- Tab Aktif menjadi bagian yang terlihat tidak aktif.

```text
       Tab Aktif
       #F9F9F9

                         TAB NON-AKTIF
                       ┌──────────────┐
                       │  Non-Aktif   │  ← #FFFFFF
                       └──────────────┘
       ┌────────────────────────────┐
       │      AREA DAFTAR            │
       │         #FFFFFF             │
       │                             │
       └────────────────────────────┘
```

### Aturan penting

Jangan membuat tab aktif terlihat seperti tombol terpisah dengan border tebal.

Gunakan **perbedaan background** sebagai indikator utama:

| State | Tab Aktif | Tab Tidak Aktif | Content |
|---|---|---|---|
| Aktif | `#FFFFFF` | `#F9F9F9` | `#FFFFFF` |
| Non-Aktif | `#F9F9F9` | `#FFFFFF` | `#FFFFFF` |

Catatan: Pada baris kedua, istilah **Tab Aktif** berarti posisi tab "Aktif", bukan tab yang sedang dipilih.

---

## 4. Search Bar

Search bar **wajib berada di atas tab Aktif/Non-Aktif**.

Search bar bersifat global terhadap daftar pengunjung dan tetap tersedia ketika pengguna berpindah tab.

### Posisi

```text
Daftar Pengunjung

[ 🔍  Cari nama pengunjung... ]

[      Aktif      ][    Non-Aktif    ]

Nama Pengunjung                 Status
...
```

### Spesifikasi

- Posisi: di bawah judul halaman.
- Jarak judul → search bar: sekitar `20–24 px`.
- Jarak search bar → tab: sekitar `12–16 px`.
- Tinggi: sekitar `40–44 px`.
- Corner radius: sekitar `10–12 px`.
- Background: `#F9F9F9` atau putih dengan border abu-abu sangat tipis.
- Placeholder: `Cari nama pengunjung...`
- Icon pencarian berada di sisi kiri.
- Search bar tidak berubah posisi ketika tab berpindah.
- Input pencarian tidak di-reset ketika berpindah tab, kecuali memang ditentukan oleh behavior aplikasi.

### Behavior

Pencarian dilakukan terhadap data yang sedang ditampilkan.

Contoh:

```text
Tab Aktif
Search: "Farizki"

→ Farizki Radiansyah
```

Kemudian ketika pengguna berpindah ke Non-Aktif:

```text
Tab Non-Aktif
Search: "Farizki"

→ Farizki Radiansyah
```

Jika ingin pencarian global terhadap seluruh data, behavior tersebut dapat diubah kemudian. Default desain ini menggunakan pencarian pada **dataset tab yang sedang aktif**.

---

## 5. Tab Switcher

Tab terdiri dari dua bagian dengan lebar yang sama:

```text
┌─────────────────────┬─────────────────────┐
│        Aktif        │      Non-Aktif      │
└─────────────────────┴─────────────────────┘
```

### Spesifikasi

- Jumlah tab: `2`
- Lebar: `50% : 50%`
- Tinggi: sekitar `40–44 px`.
- Tidak menggunakan stroke hitam.
- Tidak menggunakan shadow berat.
- Background tab tidak aktif: `#F9F9F9`.
- Background tab aktif: `#FFFFFF`.
- Text aktif: lebih tegas/dark.
- Text tidak aktif: tetap readable tetapi sedikit lebih subdued.
- Transisi perpindahan tab: sekitar `150–200 ms`.

### Efek menyatu

Area konten harus memiliki warna `#FFFFFF`.

Tab yang aktif juga memiliki warna `#FFFFFF`.

Dengan demikian:

```text
          ACTIVE TAB
       ┌───────────────┐
       │     Aktif     │
       └───────────────┘
       ┌─────────────────────────┐
       │                         │
       │       CONTENT           │
       │        #FFFFFF          │
       │                         │
       └─────────────────────────┘
```

Tidak boleh ada garis horizontal hitam yang memisahkan tab aktif dengan content.

---

## 6. Header Daftar

Header terdiri dari dua kolom:

| Kolom | Alignment |
|---|---|
| Nama Pengunjung | Left |
| Status | Center / Right |

Contoh:

```text
Nama Pengunjung                         Status
```

Typography:

- Ukuran: sekitar `12–13 px`
- Weight: `400–500`
- Warna: `#444444`

---

## 7. Row Pengunjung

Setiap row menampilkan:

```text
Farizki Radiansyah                  [ Aktif ]
```

### Spesifikasi

- Tinggi row: sekitar `46–48 px`.
- Nama pengunjung: left aligned.
- Status badge: right aligned.
- Padding horizontal: sekitar `12 px`.
- Antar-row menggunakan separator yang sangat halus.

Separator:

```text
#EEEEEE
```

Jangan menggunakan border hitam.

---

## 8. Status Badge

### Aktif

```text
[ Aktif ]
```

- Background: hijau terang seperti referensi.
- Rekomendasi: `#00E832` / sesuaikan dengan green token aplikasi.
- Text: `#1A1A1A` atau dark green.
- Bentuk: pill.
- Border radius: `999 px`.
- Padding horizontal: `12 px`.
- Tinggi: sekitar `20–22 px`.

### Non-Aktif

```text
[ Nonaktif ]
```

- Background: merah.
- Rekomendasi: `#FF3B3B` / sesuaikan dengan red token aplikasi.
- Text: `#1A1A1A` atau putih sesuai kontras final.
- Bentuk: pill.
- Border radius: `999 px`.
- Padding horizontal: `12 px`.
- Tinggi: sekitar `20–22 px`.

Warna status badge harus konsisten di kedua tab.

---

## 9. Data Contoh

### Tab Aktif

```text
Farizki Radiansyah
Novalino Ricsawan
Nabil Nobel
Apip Gallagher
Mario Kartika Putra
Citramawati
Farizki Radiansyah Angelica Putri
Ucup Borax
Ujang Klimis
```

Status badge:

```text
Aktif
```

### Tab Non-Aktif

```text
Farizki Radiansyah
Novalino Ricsawan
Nabil Nobel
Apip Gallagher
Asep Galon
Agus Type C
```

Status badge:

```text
Nonaktif
```

Data tersebut hanya digunakan sebagai data visual/contoh dan dapat diganti dengan data dari backend.

---

## 10. Pagination / Tab Behavior

Meskipun secara visual berbentuk tab, secara behavior kedua tab dapat dianggap sebagai dua halaman dataset.

### Ketika Aktif dipilih

```text
selectedTab = "active"

search → filter active visitors
content → active visitors
```

### Ketika Non-Aktif dipilih

```text
selectedTab = "inactive"

search → filter inactive visitors
content → inactive visitors
```

Perpindahan tab tidak boleh mengubah:

- Posisi search bar
- Posisi header
- Bottom navigation
- Judul halaman

Yang berubah hanya dataset dan state visual tab.

---

## 11. Empty State

Jika hasil pencarian tidak ditemukan:

```text
        Tidak ada pengunjung
        yang sesuai pencarian.
```

Jika dataset tab memang kosong:

```text
        Belum ada pengunjung
        dalam kategori ini.
```

Empty state harus tetap berada di area content `#FFFFFF`.

---

## 12. Bottom Navigation

Bottom navigation tetap mengikuti referensi:

```text
┌────────────────────────────────────┐
│                                    │
│                                    │
│  🏠 Beranda     +     👥 Pengunjung│
└────────────────────────────────────┘
```

### Elemen

1. **Beranda**
2. Tombol **Tambah (+)**
3. **Pengunjung**

Halaman Pengunjung merupakan navigation item aktif.

Tombol `+` berada di tengah dan berbentuk lingkaran.

---

## 13. Spacing

Gunakan sistem spacing konsisten:

- `4 px` — micro spacing
- `8 px` — spacing kecil
- `12 px` — spacing antar elemen dekat
- `16 px` — padding utama
- `20–24 px` — spacing section
- `32 px` — spacing besar

Layout utama harus memiliki horizontal padding sekitar `20–24 px`, mengikuti proporsi desain referensi.

---

## 14. Typography

Gunakan font sans-serif modern.

Rekomendasi:

- iOS: SF Pro
- Android/Web: Inter atau system sans-serif

Hierarchy:

```text
Daftar Pengunjung
20–22 px / Semibold

Tab
12–14 px / Medium

Header
12–13 px / Regular-Medium

Nama Pengunjung
12–13 px / Regular

Status
11–12 px / Regular
```

---

## 15. Responsive Behavior

Layout harus tetap usable pada layar mobile dengan lebar berbeda.

### Minimum requirement

- Search bar: full available width.
- Tab: selalu 50/50.
- Nama pengunjung: flexible width.
- Status: fixed/min-content width.
- Nama panjang tidak boleh membuat status badge keluar layar.

Untuk nama panjang:

```text
Farizki Radiansyah Angelica Putri
```

gunakan truncation jika diperlukan:

```text
Farizki Radiansyah Angelica...
```

---

## 16. Interaction

### Tap Aktif

```text
User tap "Aktif"
        ↓
selectedTab = active
        ↓
Tab Aktif → #FFFFFF
Tab Non-Aktif → #F9F9F9
Content → data aktif
```

### Tap Non-Aktif

```text
User tap "Non-Aktif"
        ↓
selectedTab = inactive
        ↓
Tab Non-Aktif → #FFFFFF
Tab Aktif → #F9F9F9
Content → data non-aktif
```

### Search

```text
User mengetik
        ↓
Filter dataset tab saat ini
        ↓
Update list secara langsung
```

---

## 17. Prinsip Visual Utama

Desain final harus mengikuti lima prinsip:

1. **Tidak ada stroke hitam pada tab.**
2. **Tab aktif dan content memiliki background yang sama (`#FFFFFF`).**
3. **Tab tidak aktif menggunakan `#F9F9F9`.**
4. **Search bar selalu berada di atas tab.**
5. **Perpindahan Aktif ↔ Non-Aktif terasa seperti berpindah halaman dataset, bukan membuka tombol baru.**

Tujuan akhirnya adalah menghasilkan visual seperti:

```text
STATE: AKTIF

[ Search Bar                         ]

[      AKTIF       ][   NON-AKTIF   ]
┌────────────────────────────────────┐
│ Nama Pengunjung             Status │
│                                    │
│ Farizki Radiansyah          Aktif  │
│ Novalino Ricsawan            Aktif  │
│ Nabil Nobel                  Aktif  │
│ ...                                │
└────────────────────────────────────┘


STATE: NON-AKTIF

[ Search Bar                         ]

[      AKTIF       ][   NON-AKTIF   ]
┌────────────────────────────────────┐
│ Nama Pengunjung             Status │
│                                    │
│ Farizki Radiansyah        Nonaktif │
│ Novalino Ricsawan         Nonaktif │
│ Nabil Nobel               Nonaktif │
│ ...                                │
└────────────────────────────────────┘
```

**Kunci desain:** tab yang sedang dipilih harus terasa menjadi bagian dari panel putih di bawahnya, sementara tab yang tidak dipilih terlihat sebagai area abu-abu `#F9F9F9`. Stroke hitam pada gambar referensi tidak termasuk dalam implementasi final.
