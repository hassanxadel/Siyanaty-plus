# Google Maps API Configuration Guide

## Issue Summary
The Google Maps is showing a white screen with "Failed to load service centers: Exception: Places API error: REQUEST_DENIED" because the API key needs proper configuration in Google Cloud Console.

## Step-by-Step Solution

### 1. Google Cloud Console Setup

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Select your project** (or create a new one if needed)
3. **Enable Required APIs**:
   - Go to "APIs & Services" → "Library"
   - Search and enable these APIs:
     - ✅ **Maps SDK for Android**
     - ✅ **Places API** 
     - ✅ **Directions API**
     - ✅ **Geocoding API**

### 2. API Key Configuration

1. **Go to "APIs & Services" → "Credentials"**
2. **Find your API key** (`AIzaSyCtDx-w7cQCYMCS-xEKRcOVzp_l5wk_A7A`)
3. **Click "Edit" on your API key**
4. **Configure Application Restrictions**:
   - Select "Android apps"
   - Add your package name: `com.example.siyanaty`
   - Add SHA-1 fingerprint (see step 3 below)

### 3. Get SHA-1 Fingerprint

**For Debug (Development):**
```bash
cd android
./gradlew signingReport
```
Look for the SHA1 fingerprint under "Variant: debug" → "Config: debug"

**Alternative method:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### 4. API Key Restrictions

In the API key settings:
- **Application restrictions**: Android apps
- **Package name**: `com.example.siyanaty`
- **SHA-1 certificate fingerprint**: [Your debug SHA-1 from step 3]
- **API restrictions**: Select "Restrict key" and choose:
  - Maps SDK for Android
  - Places API
  - Directions API
  - Geocoding API

### 5. Billing Account

⚠️ **Important**: Make sure your Google Cloud project has a billing account enabled. Places API requires billing even for free tier usage.

### 6. Test the Configuration

1. **Save the API key settings**
2. **Wait 5-10 minutes** for changes to propagate
3. **Restart your Flutter app**
4. **Check the logs** for any remaining errors

## Expected Behavior After Fix

✅ **Location**: Should show your actual location (or emulator default with a warning)
✅ **Service Centers**: Should find nearby car repair shops
✅ **Map**: Should display in full mode (not lite mode)
✅ **Favorites**: Should be able to save/load favorite service centers

## Troubleshooting

### If still getting REQUEST_DENIED:
1. Double-check package name matches exactly: `com.example.siyanaty`
2. Verify SHA-1 fingerprint is correct
3. Ensure all required APIs are enabled
4. Check billing account is active
5. Wait up to 10 minutes for changes to take effect

### If getting ZERO_RESULTS:
- This is normal for some locations (especially Google HQ default location)
- Try testing with a real device in an area with car repair shops

### For Emulator Testing:
- The app will show "Using emulator default location (Google HQ)" 
- This is expected behavior - use a real device for actual location testing

## Files Updated

1. ✅ **firestore.rules** - Added permissions for favorite_service_centers and OCR scans
2. ✅ **services_screen.dart** - Improved error handling and disabled lite mode
3. ✅ **Location handling** - Better emulator detection and fallback locations

## Next Steps

1. Follow the Google Cloud Console configuration above
2. Test on a real device for accurate location
3. The service centers feature should work properly after API configuration

---

**Note**: The current API key in the code is visible and should be restricted properly in production. Consider using environment variables or Firebase Remote Config for better security.
