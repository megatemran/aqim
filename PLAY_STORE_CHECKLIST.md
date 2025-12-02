# ✅ Google Play Store Upload Checklist - Aqim

## 📱 App Build Status
- [x] **Release AAB Built**: Successfully created at `build\app\outputs\bundle\release\app-release.aab` (120.7MB)
- [x] **Signing Configuration**: Configured in `android/key.properties`
- [x] **App Icons**: Generated in all required densities (mipmap folders)

---

## ⚠️ CRITICAL - Must Fix Before Upload

### 1. **Privacy Policy** (REQUIRED) ✅ DONE
- [x] **Create Privacy Policy**: You MUST have a privacy policy because your app:
  - Collects location data (GPS for prayer times)
  - Uses camera (for rakaat counter)
  - Shows ads (AdMob)
  - Requests notifications permission

- [x] **Host privacy policy online** (required URL for Play Store):
  - ✅ **Hosted at**: https://megatemran.github.io/aqim/privacy-policy.html
  - ✅ **Terms URL**: https://megatemran.github.io/aqim/terms.html
  - ✅ **Bilingual**: English & Bahasa Melayu
  - ✅ **Comprehensive**: Covers all data collection, permissions, and third-party services

**Required Privacy Policy Content:**
```
1. What data is collected:
   - Location data (for prayer time calculations)
   - Camera access (for pose detection/rakaat counter)

2. How data is used:
   - Location: Calculate accurate prayer times based on user's location
   - Camera: Real-time pose detection for prayer rakaat counting

3. Data sharing:
   - We do not sell or share personal data
   - Google AdMob may collect advertising data (link to Google's privacy policy)
   - e-Solat Malaysia API is used for Malaysian prayer times
   - AlAdhan API for international prayer times

4. Data storage:
   - Location data is cached locally on device
   - Prayer times cached for 24 hours
   - No server-side data storage

5. User rights:
   - Users can deny location permission (app will use fallback location)
   - Users can deny camera permission (rakaat counter won't work)
   - All data can be cleared by uninstalling the app
```

### 2. **App Description Update** ✅ DONE
- [x] Update `pubspec.yaml` description
  - ✅ Current: "Aqim - Prayer Times & Qibla app for Malaysia. Accurate Malaysian prayer times, automatic azan, qibla compass, daily duas, and beautiful home screen widgets."

### 3. **AdMob Configuration**
- [x] AdMob App ID configured: `ca-app-pub-7677814397287910~6615544657`
- [ ] **Verify all ad units are approved in AdMob console**
- [ ] **Add app to AdMob app list**

### 4. **Permissions Explanation**
When uploading to Play Store, you'll need to explain why each permission is needed:

| Permission | Reason |
|------------|--------|
| `INTERNET` | Fetch prayer times from e-Solat Malaysia/AlAdhan API, show ads |
| `CAMERA` | Pose detection for rakaat counter feature |
| `ACCESS_FINE_LOCATION` | Calculate prayer times based on user's precise location |
| `POST_NOTIFICATIONS` | Send prayer time notifications/alarms |
| `SCHEDULE_EXACT_ALARM` | Trigger prayer alarms at exact prayer times |
| `RECEIVE_BOOT_COMPLETED` | Reschedule alarms after device restart |
| `WAKE_LOCK` | Wake device for prayer alarm notifications |
| `USE_EXACT_ALARM` | Precise alarm scheduling for prayer times |
| `VIBRATE` | Vibrate phone when prayer time arrives |
| `USE_FULL_SCREEN_INTENT` | Show full-screen prayer alarm notification |

---

## 📋 Play Store Listing Requirements

### App Information
- **App Name** (max 50 chars): See below for Bahasa/English versions
- **Short Description** (max 80 chars): See below
- **Full Description** (max 4000 chars): See below
- **Category**: Lifestyle
- **Content Rating**: Everyone
- **Target Audience**: 18+
- **Contact Email**: (Your email)
- **Website**: https://www.aqim.my (or your website)

### Screenshots Required
- [ ] **Minimum 2 screenshots** (recommended: 4-8)
  - Phone screenshots: 1080x1920 or 1080x2340 (your device resolution)
  - Capture:
    1. Home screen with prayer times
    2. Prayer times list screen
    3. Qibla compass
    4. Duas screen
    5. Widgets screen showing widget previews
    6. Rakaat counter screen (optional)
    7. Azan full screen notification

### Feature Graphic
- [ ] **Feature Graphic**: 1024x500px PNG/JPEG
  - Required for featured placement
  - Create promotional banner with app logo and key features

### App Icon
- [x] Already configured: `assets/icon/appicon.png`
- [ ] Verify it meets requirements:
  - 512x512px PNG (32-bit)
  - No alpha/transparency
  - Full bleed (no white space)

---

## 🔍 Content Rating Questionnaire
When filling out the content rating questionnaire:

- **Violence**: None
- **Sexual Content**: None
- **Language**: None
- **Controlled Substances**: None
- **Gambling**: None
- **Ads**: **YES** (AdMob banners/interstitials)
- **Location Sharing**: **YES** (for prayer times)
- **User-Generated Content**: None
- **Personal Information**: **YES** (location data)

---

## 🌍 Store Listing Translations

### Default Language: English (UK/US)
Then add **Bahasa Melayu** as additional language

---

## 📝 Data Safety Section (IMPORTANT)
You must fill out the Data Safety form declaring:

**Data Collected:**
- ✅ **Location** (Approximate & Precise)
  - Purpose: "App functionality" (prayer time calculation)
  - Sharing: Not shared with third parties
  - Optional: No (required for core functionality)

- ✅ **Device or other IDs** (via AdMob)
  - Purpose: "Advertising or marketing"
  - Sharing: Shared with Google AdMob
  - Optional: Yes

**Data Security:**
- Data encrypted in transit: Yes (HTTPS APIs)
- User can request data deletion: Yes (uninstall app)
- Privacy policy: (Your privacy policy URL)

---

## 🚀 Pre-Launch Checklist

### Testing
- [x] App builds successfully in release mode
- [ ] Test on multiple devices/Android versions
- [ ] Test all features:
  - [ ] Prayer times load correctly
  - [ ] Alarms trigger at correct times
  - [ ] Location permission flow works
  - [ ] Qibla compass functions
  - [ ] Widgets can be added to home screen
  - [ ] Ads display correctly (test mode OFF for release)
  - [ ] Camera/rakaat counter works

### Version Management
- [x] **Current version**: 1.0.0+1
- [ ] For updates, increment version:
  - Major update: 2.0.0+2
  - Minor update: 1.1.0+2
  - Patch: 1.0.1+2

### Build Preparation
- [ ] Remove all debug code/logs (optional, already using debugPrint)
- [ ] Verify AdMob uses production ad unit IDs (✅ done)
- [ ] Test with `--release` flag on real device
- [ ] Check app size (120.7MB - consider optimization if needed)

---

## 📦 Upload Files Checklist

When ready to upload:
- [ ] **AAB file**: `build\app\outputs\bundle\release\app-release.aab`
- [ ] **Screenshots**: 4-8 phone screenshots
- [ ] **Feature graphic**: 1024x500px
- [ ] **App icon**: 512x512px (high-res)
- [ ] **Privacy policy URL**
- [ ] **Release notes** (Bahasa + English)

---

## ⚡ Quick Fixes Needed NOW

1. **Create Privacy Policy** - URGENT
2. **Update pubspec.yaml description**
3. **Prepare screenshots**
4. **Create feature graphic**

---

## 📞 Support
- GitHub: (your repo if public)
- Email: (your support email)
- Website: https://www.aqim.my

---

---

## ✅ Current Status Summary

### COMPLETED ✅
- [x] AAB file built and signed (121MB at `build\app\outputs\bundle\release\app-release.aab`)
- [x] Privacy Policy created and hosted (bilingual) ✅ https://megatemran.github.io/aqim/privacy-policy.html
- [x] Terms of Service created and hosted (bilingual) ✅ https://megatemran.github.io/aqim/terms.html
- [x] App description updated in pubspec.yaml
- [x] AdMob configured with production IDs
- [x] App icons generated in all densities
- [x] Signing configuration done (keystore configured)

### REMAINING TASKS ⚠️

**HIGH PRIORITY (Required for Upload):**
1. [x] ~~**Update pubspec.yaml description**~~ - ✅ Already done!
2. [ ] **Prepare Screenshots** (minimum 2, recommended 4-8):
   - Home screen with prayer times
   - Qibla compass
   - Prayer notifications
   - Duas/Hadith screen
   - Widget preview
   - Settings screen
3. [ ] **Create Feature Graphic** (1024x500px) - Banner for Play Store
4. [ ] **Test on multiple Android devices** (different versions: 5.0 to 14)

**MEDIUM PRIORITY (During Upload Process):**
5. [ ] Fill out **Data Safety** section in Play Console
6. [ ] Complete **Content Rating** questionnaire
7. [ ] Add **Release Notes** (English + Bahasa Melayu)

**LOW PRIORITY (Optional):**
8. [ ] Create promotional video (YouTube, 30s-2min)
9. [ ] Tablet screenshots
10. [ ] App size optimization (current: 120.7MB)

---

## 🎯 Next Steps (In Order)

1. ~~**Update App Description**~~ ✅ DONE

2. **Take Screenshots** (30-60 minutes)
   - Use Android emulator or real device
   - Screenshot resolution: 1080x1920 or 1080x2340
   - Showcase all major features
   - Make sure UI looks clean (no test data)

3. **Create Feature Graphic** (30-60 minutes)
   - Use Canva, Figma, or Photoshop
   - Size: 1024x500px
   - Include app logo and tagline
   - Showcase 2-3 key features

4. **Final Testing** (1-2 hours)
   - Test on different Android versions
   - Verify all permissions work
   - Check prayer times accuracy
   - Test alarms and notifications
   - Verify ads display correctly

5. **Upload to Play Console** (1-2 hours)
   - Upload AAB
   - Fill store listing
   - Add screenshots and graphics
   - Complete data safety form
   - Complete content rating
   - Submit for review

**Estimated Time to Launch**: 4-6 hours of work

**Status**: 🟡 Almost ready - Need store assets (screenshots + graphic) and final testing
