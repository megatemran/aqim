
git add .
git commit -m "Add app-ads.txt for AdMob verification"
git push origin main


Website: https://megatemran.github.io/aqim/website/
Privacy Policy: https://megatemran.github.io/aqim/privacy-policy.html
Terms of Service: https://megatemran.github.io/aqim/terms.html

adb shell am broadcast -a net.brings2you.aqim.PRAYER_ALARM \
    -p net.brings2you.aqim \
    --es prayer_name "Asar" \
    --es prayer_time "16:30"