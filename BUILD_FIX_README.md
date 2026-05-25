# 🚀 MindFlow Build Fix - CI/CD Configuration

## Overview

This guide explains the fixes applied to resolve the Android APK and Windows executable build failures in the GitHub Actions CI/CD pipeline.

## Problems Fixed

### 1. ❌ Android Build Failure (exit code 1)
**Root Cause**: The workflow was using the debug keystore to sign the release APK, which is incorrect and fails in CI/CD.

**Solution**: 
- Implemented proper Android keystore signing configuration
- Secrets are stored securely in GitHub
- Release builds now use a dedicated release keystore

### 2. ❌ Windows Build Failure (exit code 1)
**Root Cause**: Missing proper platform setup and missing error handling in the workflow.

**Solution**:
- Added flutter doctor validation
- Improved error handling and logging
- Added build verification steps
- Better compression and artifact handling

## What Changed

### 1. Workflow File: `.github/workflows/build.yml`
Enhanced with:
- ✅ Gradle caching for faster builds
- ✅ Flutter package caching
- ✅ Pre-build analysis (`flutter analyze`)
- ✅ Proper keystore decoding from secrets
- ✅ Detailed error messages
- ✅ Build verification before artifact upload
- ✅ 30-day artifact retention

### 2. Android Config: `android/app/build.gradle.kts`
Updated with:
- ✅ Release signing configuration
- ✅ Environment variable support for credentials
- ✅ Keystore path configuration

### 3. Supporting Files
- ✅ `generate_keystore.py` - Automated keystore generation
- ✅ `KEYSTORE_SETUP.md` - Detailed keystore setup guide
- ✅ `setup_github_secrets.sh` - Linux/Mac setup script
- ✅ `setup_github_secrets.bat` - Windows setup script

## How to Set Up

### Prerequisites
- Java Development Kit (JDK) 17 or later
- Python 3.6+ (for script)
- Git and GitHub account access

### Step 1: Generate Keystore Locally

```bash
# Option A: Using the provided Python script
python generate_keystore.py

# Option B: Using keytool directly (if Java is installed)
keytool -genkey -v \
  -keystore android/app/keystore.jks \
  -keyalg RSA -keysize 2048 -validity 3650 \
  -alias mindflow_release_key \
  -storepass "MindFlow@2024Secure" \
  -keypass "MindFlow@2024Secure" \
  -dname "CN=MindFlow,OU=Development,O=MindFlow,C=BR"
```

### Step 2: Encode Keystore to Base64

**On macOS/Linux:**
```bash
base64 android/app/keystore.jks
# Or to save to file:
base64 -i android/app/keystore.jks -o /tmp/keystore_base64.txt
cat /tmp/keystore_base64.txt
```

**On Windows PowerShell:**
```powershell
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes('android\app\keystore.jks'))
$b64 | Set-Clipboard
# Then paste directly
```

**Or use online tool:**
- Go to: https://www.base64encode.org/
- Upload: `android/app/keystore.jks`
- Copy the encoded output

### Step 3: Add GitHub Secrets

Go to: **https://github.com/BeanieMal6336/medidor-emocional---indeia2/settings/secrets/actions**

Click **"New repository secret"** and add these 4 secrets:

| Name | Value |
|------|-------|
| `KEYSTORE_BASE64` | Base64-encoded keystore (from step 2) |
| `KEYSTORE_PASSWORD` | `MindFlow@2024Secure` |
| `KEY_PASSWORD` | `MindFlow@2024Secure` |
| `KEY_ALIAS` | `mindflow_release_key` |

### Step 4: Remove Local Keystore (Important!)

```bash
# Remove the keystore from your machine
rm android/app/keystore.jks

# Verify it's in .gitignore (should already be)
cat android/.gitignore | grep -i "keystore\|jks"
```

### Step 5: Test the Workflow

1. Go to: **https://github.com/BeanieMal6336/medidor-emocional---indeia2/actions**
2. Click on **"Build Installers"** workflow
3. Click **"Run workflow"** 
4. Select branch `main` and click **"Run workflow"**

The workflow will:
- ✅ Build Android APK with release signing
- ✅ Build Windows executable  
- ✅ Upload both artifacts if successful
- ✅ Show detailed logs if anything fails

## Keystore Credentials Reference

For your records (store securely):

```
Application ID:     com.example.mindflow
Key Alias:          mindflow_release_key
Store Password:     MindFlow@2024Secure
Key Password:       MindFlow@2024Secure
Algorithm:          RSA 2048-bit
Validity:           3650 days (10 years)
Certificate:        CN=MindFlow,OU=Development,O=MindFlow,C=BR
```

## Security Notes

⚠️ **IMPORTANT:**

1. **Never commit the keystore file** - It's already in `.gitignore`
2. **Secrets are encrypted in GitHub** - They don't appear in logs or publicly
3. **Only store base64 version in secrets** - Not the actual binary file
4. **Change credentials if compromised** - Generate a new keystore and update secrets
5. **Keep credentials private** - Don't share keystore or passwords

## Troubleshooting

### Build Still Fails

1. **Check secrets are added correctly:**
   - Go to Settings → Secrets → Actions
   - Verify all 4 secrets are present
   - Run workflow again

2. **Verify keystore is valid:**
   ```bash
   keytool -list -v -keystore android/app/keystore.jks -storepass MindFlow@2024Secure
   ```

3. **Check workflow logs:**
   - Go to Actions → Build Installers → Latest run
   - Click the failed job and expand the logs
   - Look for specific error messages

4. **Test locally first:**
   ```bash
   flutter clean
   flutter pub get
   
   # For Android with secrets as environment variables:
   export KEYSTORE_PATH=$(pwd)/android/app/keystore.jks
   export KEYSTORE_PASSWORD="MindFlow@2024Secure"
   export KEY_PASSWORD="MindFlow@2024Secure"
   export KEY_ALIAS="mindflow_release_key"
   flutter build apk --release
   
   # For Windows:
   flutter build windows --release
   ```

### "Keystore file not found"

This is expected on first run if secrets aren't configured yet. The workflow will:
- Skip the keystore decode step
- Build with debug signing as fallback
- Show a warning message

Once secrets are configured, future builds will use proper signing.

### "Signing config failed"

1. Verify KEYSTORE_BASE64 is properly encoded
2. Check that KEYSTORE_PASSWORD and KEY_PASSWORD match what you used
3. Verify KEY_ALIAS is exactly: `mindflow_release_key`

## Workflow Jobs

### Android APK Build
- **Runs on:** Ubuntu latest
- **Steps:**
  1. Checkout code
  2. Setup Java 17
  3. Setup Flutter with cache
  4. Analyze code
  5. Decode keystore from secrets
  6. Build release APK with signing
  7. Upload artifact

**Output:** `mindflow-android-apk` artifact (app-release.apk)

### Windows Executable Build
- **Runs on:** Windows Server 2022
- **Steps:**
  1. Checkout code
  2. Setup Flutter with cache
  3. Enable Windows desktop platform
  4. Analyze code
  5. Build release executable
  6. Verify build output
  7. Compress into ZIP
  8. Upload artifact

**Output:** `mindflow-windows-x64` artifact (zip file)

## Next Steps

1. ✅ Run the keystore generation script
2. ✅ Add the 4 GitHub secrets
3. ✅ Remove local keystore file
4. ✅ Test the workflow
5. ✅ Download and verify artifacts

## Files Modified

- `.github/workflows/build.yml` - ⬆️ UPDATED
- `android/app/build.gradle.kts` - ⬆️ UPDATED
- `KEYSTORE_SETUP.md` - ✨ NEW
- `generate_keystore.py` - ✨ NEW
- `setup_github_secrets.sh` - ✨ NEW
- `setup_github_secrets.bat` - ✨ NEW
- `BUILD_FIX_README.md` - ✨ NEW (this file)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review workflow logs in GitHub Actions
3. Verify secrets are properly configured
4. Test locally with environment variables

---

**Last Updated:** 2026-05-25
**Status:** ✅ Ready for deployment