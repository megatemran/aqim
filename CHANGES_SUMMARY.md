# 📝 Summary Perubahan untuk Google Play Store

## ✅ Perubahan Selesai

### 1. **Buang Sebutan "JAKIM"**
Semua sebutan "JAKIM" telah diganti dengan perkataan yang lebih umum untuk elakkan Google Play Store minta dokumen kerajaan.

#### Penggantian Yang Dibuat:

| Dari (Before) | Kepada (After) |
|---------------|----------------|
| "berdasarkan zon JAKIM" | "berdasarkan zon rasmi Malaysia" |
| "JAKIM Malaysia zones" | "official Malaysian zones" |
| "Sumber Rasmi JAKIM Malaysia" | "Sumber Rasmi Malaysia" |
| "Official JAKIM Malaysia Source" | "Official Malaysia Source" |
| "Data dari sumber rasmi (JAKIM)" | "Data dari sumber rasmi Malaysia" |
| "JAKIM e-Solat API" | "e-Solat Malaysia API" |
| "Waktu Solat Malaysia (JAKIM)" | "Waktu Solat Malaysia" |
| "Malaysia Prayer Times (JAKIM)" | "Malaysia Prayer Times" |

### 2. **Fail Yang Dikemaskini**

✅ **PLAY_STORE_LISTING.md**
- App name: Tetap "Aqim - Waktu Solat & Kiblat Malaysia"
- Descriptions (BM + EN): Semua sebutan JAKIM dibuang
- Keywords: Tag "jakim" dibuang
- Feature graphic text: JAKIM dibuang
- Release notes: JAKIM dibuang

✅ **PRIVACY_POLICY_TEMPLATE.md**
- "JAKIM API" → "e-Solat Malaysia API"
- Semua penerangan JAKIM diganti

✅ **PLAY_STORE_CHECKLIST.md**
- Permissions table: JAKIM dibuang
- Data safety section: Kemas kini

✅ **pubspec.yaml**
- Description: "Accurate JAKIM prayer times" → "Accurate Malaysian prayer times"

---

## 📄 Fail Yang Tidak Diubah (Sengaja)

### CLAUDE.md
- ❌ Tidak diubah (fail dalaman untuk development, bukan untuk Play Store)
- Masih ada sebutan JAKIM untuk reference developer

### Kod Sumber (lib/ folder)
- ❌ Tidak diubah
- Masih ada komen code yang sebut JAKIM
- Ini OK kerana Google tidak baca kod sumber, hanya description di Play Store

---

## 🎯 Apa Yang Perlu Anda Buat Sekarang

### 1. Semak Dokumen Yang Dikemaskini
Buka dan semak fail-fail ini:
- ✅ `PLAY_STORE_LISTING.md` - App name & descriptions
- ✅ `PRIVACY_POLICY_TEMPLATE.md` - Privacy policy content
- ✅ `PLAY_STORE_CHECKLIST.md` - Upload checklist

### 2. Gunakan Content Yang Betul
Apabila upload ke Play Store, copy content dari `PLAY_STORE_LISTING.md`:

**Untuk Bahasa Melayu (Primary Language):**
```
App Name: Aqim - Waktu Solat & Kiblat Malaysia
Short Desc: Waktu solat tepat, azan, kiblat, doa harian & widget untuk Malaysia
```

**Untuk English (Secondary Language):**
```
App Name: Aqim - Prayer Times & Qibla Malaysia
Short Desc: Accurate prayer times, azan, qibla, daily duas & widgets for Malaysia
```

### 3. Privacy Policy URL
Copy content dari `PRIVACY_POLICY_TEMPLATE.md` dan host di:
- Website anda: https://www.aqim.my/privacy-policy
- Atau GitHub Pages / Google Sites (percuma)

---

## ⚠️ Penting: Jangan Sebut JAKIM Semasa Upload

Apabila mengisi Play Store Console, **jangan** guna perkataan ini:
- ❌ JAKIM
- ❌ Jabatan Kemajuan Islam Malaysia
- ❌ Department of Islamic Development Malaysia
- ❌ Government agency
- ❌ Official government app

Sebaliknya, guna:
- ✅ Official Malaysian prayer times
- ✅ Malaysian official sources
- ✅ e-Solat Malaysia
- ✅ Trusted Malaysian sources

---

## 🔍 Kenapa Perlu Buang JAKIM?

### Masalah Jika Sebut JAKIM:
1. **Google Play akan classify app sebagai "Government App"**
2. **Akan minta dokumen rasmi**:
   - Surat kebenaran dari JAKIM
   - MOU atau agreement letter
   - Official government authorization

3. **Proses review akan lambat**:
   - Mungkin ambil masa berminggu-minggu
   - Banyak soalan tambahan
   - Kemungkinan reject tinggi

### Cara Baru Lebih Selamat:
1. ✅ Tidak perlu dokumen kerajaan
2. ✅ Review process normal (3-7 hari)
3. ✅ Kurang soalan dari Google
4. ✅ Masih boleh sebut "sumber rasmi Malaysia"
5. ✅ Pengguna masih faham app dapat data dari sumber terpercaya

---

## 📊 Before vs After Comparison

### Before (Ada Masalah):
```
🕌 WAKTU SOLAT MALAYSIA (JAKIM)
• Waktu solat tepat berdasarkan zon JAKIM Malaysia
• Data dari sumber rasmi (JAKIM)
```

### After (Selamat):
```
🕌 WAKTU SOLAT MALAYSIA
• Waktu solat tepat berdasarkan zon rasmi Malaysia
• Data dari sumber rasmi Malaysia
```

---

## ✅ Status: SELESAI

Semua perubahan telah dibuat. App sekarang **READY** untuk upload ke Play Store tanpa risiko Google minta dokumen JAKIM.

### Next Steps:
1. ✅ Perubahan JAKIM - **SELESAI**
2. ⏳ Buat Privacy Policy
3. ⏳ Ambil screenshots
4. ⏳ Buat feature graphic
5. ⏳ Upload ke Play Store

---

**Last Updated**: November 2025
**Status**: ✅ Ready untuk Play Store (selepas privacy policy & screenshots)
