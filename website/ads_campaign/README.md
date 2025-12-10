# Aqim - HTML5 Ad Campaigns

This folder contains HTML5 advertisements for the Aqim app in various dimensions.

## 📐 Available Ad Sizes

### HTML5 Upload Ready (For Ad Networks)
These ads meet the standard HTML5 upload requirements:
- **320x480.html** - Portrait mobile banner
- **480x320.html** - Landscape mobile banner

### Standard Web Banner Sizes
These are traditional web banner dimensions:
- **320x50.html** - Mobile leaderboard
- **300x250.html** - Medium rectangle
- **728x90.html** - Leaderboard
- **300x600.html** - Half page
- **160x600.html** - Wide skyscraper

## 📦 HTML5 Upload Requirements

When uploading HTML5 ads to ad networks (e.g., Google AdMob, AdSense, etc.), ensure you follow these requirements:

### File Format
- **Format:** .ZIP file only
- **Max files in ZIP:** 512 files
- **Max file size:** 5MB (total ZIP size)

### Required Dimensions
HTML5 uploads must use one of these exact dimensions:
- **320x480** (portrait mobile)
- **480x320** (landscape mobile)

### How to Prepare HTML5 Ads for Upload

#### Option 1: Single File ZIP (Recommended)
If your HTML is self-contained (no external assets):

```bash
# For 320x480
zip aqim-320x480.zip 320x480.html

# For 480x320
zip aqim-480x320.zip 480x320.html
```

#### Option 2: Multi-File ZIP (With Assets)
If you have external assets (images, CSS, JS files):

```bash
# Create a folder structure
mkdir aqim-320x480
cp 320x480.html aqim-320x480/index.html
# Add your assets to the folder
cp -r images/ aqim-320x480/images/
cp -r css/ aqim-320x480/css/

# Create ZIP
zip -r aqim-320x480.zip aqim-320x480/

# Ensure ZIP size is under 5MB
ls -lh aqim-320x480.zip
```

### Important Notes

1. **Entry Point:** The main HTML file should be named `index.html` inside the ZIP
2. **Self-Contained:** All assets (images, fonts, styles) must be inside the ZIP
3. **No External Resources:** Cannot link to external CDNs or external files
4. **Click URL:** Add clickTag parameter for ad network click tracking
5. **File Limit:** Maximum 512 files within the ZIP
6. **Size Limit:** Total ZIP file must be under 5MB

## 🎨 Ad Features

All ads include:
- Responsive design optimized for mobile devices
- Animated backgrounds and effects
- Clear call-to-action button
- App branding (logo, name, colors)
- Star rating display (4.8 stars)
- Download count (10K+)
- Automatic redirect to Play Store on click

## 🔗 Click Tracking

All ads are configured to open the Aqim app on Google Play Store:
```
https://play.google.com/store/apps/details?id=net.brings2you.aqim
```

## 🛠️ Customization

To modify the ads:

1. **Colors:** Edit the CSS variables in the `<style>` section
   - Primary: `#1A5F4F` (green)
   - Accent: `#F4743B` (orange)

2. **Content:** Update text in the HTML structure
   - App name: `AQIM`
   - Headline: `Waktu Solat Tepat & Mudah`
   - Features: GPS, Azan, Kiblat, Doa

3. **Animations:** Modify CSS keyframes for different effects

## 📊 Performance Tips

1. Keep total file size under 1MB for faster loading
2. Use inline CSS and JS instead of external files
3. Optimize animations for mobile performance
4. Test on actual devices before deployment
5. Use compressed/optimized images if adding assets

## ✅ Pre-Upload Checklist

Before uploading to ad network:

- [ ] HTML file validates without errors
- [ ] Dimensions are exactly 320x480 or 480x320
- [ ] All assets are self-contained in ZIP
- [ ] ZIP file is under 5MB
- [ ] Less than 512 files in ZIP
- [ ] Click tracking works correctly
- [ ] Tested on mobile devices
- [ ] All animations work smoothly

## 📝 Ad Network Guidelines

### Google AdMob / AdSense
- Supports HTML5 creative uploads
- Maximum file size: 5MB
- Supported formats: ZIP
- Required dimensions: 320x480, 480x320

### Facebook Audience Network
- Supports HTML5 ads
- Maximum file size: 2MB
- Must include proper click tracking

### Unity Ads
- Supports HTML5 playable ads
- Maximum file size: 5MB
- Must work offline (all assets bundled)

## 🚀 Deployment

1. Choose the appropriate ad size (320x480 or 480x320)
2. Create ZIP file with the HTML
3. Upload to your ad network dashboard
4. Set targeting and budget
5. Monitor performance metrics

## 📞 Support

For issues or questions:
- Developer: megatemran
- App: Aqim - Aqimusollah
- Website: [Project Website]

## 📄 License

© 2025 Aqim - Aqimusollah. All rights reserved.
