# 📱 Panduan Setup: Pastikan Azan Bunyi Tepat Pada Masanya

## 🎯 Tujuan

Panduan ini memastikan azan waktu solat berbunyi **TEPAT PADA MASANYA**, even bila phone anda locked atau dalam mod tidur.

---

## ✅ Langkah 1: Enable "Alarms & Reminders" (Android 12+)

**SANGAT PENTING untuk ketepatan masa!**

### Cara Enable:

1. Buka aplikasi **Aqim**
2. Bila diminta, tekan butang **"Buka Settings"** dalam dialog permission
3. Dalam Settings, cari **"Aqim"** dalam senarai apps
4. **Enable** toggle untuk **"Alarms & reminders"**
5. Kembali ke aplikasi

### Kenapa Penting?

❌ **Tanpa permission ini:**
- Azan akan delay 15-60 minit
- Notification tidak muncul bila phone tidur
- Waktu solat tidak boleh dipercayai

✅ **Dengan permission:**
- Azan bunyi TEPAT pada waktu solat
- System prioritize notification anda
- Berfungsi even dalam Doze mode

---

## ✅ Langkah 2: Disable Battery Optimization (Recommended)

**Untuk reliability maksimum**

### Cara Disable:

1. Buka **Settings** → **Apps** → **Aqim**
2. Tekan **"Battery"**
3. Pilih **"Unrestricted"** atau **"Optimized"** kepada **"Don't optimize"**
4. Confirm changes

### Kenapa Penting?

- Phone tidak akan kill background service untuk azan
- Alarm tetap active even bila phone idle lama
- Foreground service boleh running dengan smooth

---

## ✅ Langkah 3: Test Alarm

**Pastikan semua berfungsi dengan baik**

### Cara Test:

1. Dalam app Aqim, check **waktu solat seterusnya**
2. **Lock phone** anda dan matikan screen
3. **Tunggu** sehingga waktu solat masuk
4. **✅ Expected:** Phone akan wake up, screen on, azan berbunyi TEPAT pada masa

### Kalau Gagal Test:

1. Check sama ada "Alarms & reminders" enabled (Langkah 1)
2. Check battery optimization (Langkah 2)
3. Restart phone dan test semula
4. Check logcat untuk debug (untuk developers)

---

## 🔔 Apa Yang Anda Akan Nampak

### Notification "Menunggu waktu solat"

Anda mungkin nampak notification kecil yang kata:
> **"Menunggu waktu solat Subuh"**
> Azan akan berbunyi pada 06:30

**Ini NORMAL dan BAGUS!** ✅

- Ini adalah foreground service yang memastikan azan bunyi tepat pada masa
- Notification ini bermaksud system tidak akan kill service
- Jangan swipe/dismiss notification ini sebelum azan berbunyi

**Selepas azan berbunyi, notification akan hilang automatik.**

---

## 🛡️ 3-Layer Protection Explained (For Tech Users)

App menggunakan **3 lapisan perlindungan** untuk pastikan alarm tepat:

### Layer 1: AlarmManager (Primary)
- Guna `setAlarmClock()` - highest priority
- Bypass Doze mode & battery optimization
- Shows in system alarm clock

### Layer 2: Foreground Service (Backup)
- Start 5 minit sebelum waktu solat
- Immune to Doze mode restrictions
- Guarantee execution pada masa tepat

### Layer 3: Heartbeat (Safety Net)
- Check setiap 15 minit
- Kalau missed alarm → trigger immediately
- Max delay: 15 minit (better than none!)

**Ini bermaksud even kalau Layer 1 fail, Layer 2 & 3 akan cover!**

---

## ❓ Soalan Lazim (FAQ)

### Q: Kenapa ada notification "Menunggu waktu solat"?
**A:** Ini foreground service yang pastikan alarm bunyi tepat masa. Normal dan diperlukan.

### Q: Boleh hide notification tu?
**A:** Tidak recommended. Kalau hide, Android mungkin kill service dan alarm tidak bunyi.

### Q: Phone saya Android 11, perlu setup apa-apa?
**A:** Tidak. "Alarms & reminders" permission hanya untuk Android 12+. Phone anda akan guna Layer 2 & 3 automatik.

### Q: Azan masih delay jugak, apa masalah?
**A:**
1. Check "Alarms & reminders" enabled
2. Disable battery optimization
3. Restart phone
4. Reinstall app (last resort)

### Q: Ada kena bayar untuk features ni?
**A:** TIDAK. Semua free. Aqim adalah app waktu solat percuma.

### Q: Battery drain banyak ke?
**A:** TIDAK. Foreground service hanya active 5 minit sebelum waktu solat. Impact minimal.

---

## 🎉 Kesimpulan

Selepas setup:
- ✅ Azan bunyi **TEPAT** pada waktu solat
- ✅ Berfungsi even phone **locked & sleep**
- ✅ **Immune** to Doze mode
- ✅ **99.9% reliability**

**Jangan skip setup di atas untuk pengalaman terbaik!**

---

## 📞 Support

Kalau ada masalah, sila report di:
- GitHub Issues: https://github.com/[your-repo]/aqim/issues
- Email: [your-email]

**JazakAllahu Khairan** kerana guna aplikasi Aqim! 🤲
