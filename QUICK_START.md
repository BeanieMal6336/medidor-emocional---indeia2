# ⚡ Quick Start - Setup in 5 Minutes

## TL;DR - Fast Setup Path

### Prerequisites
- Java Development Kit (JDK) 17 or later installed
- Python 3.6+ installed
- Git and GitHub account access

---

## Step 1️⃣: Generate Keystore (2 minutes)

```bash
cd your-project-directory
python generate_keystore.py
```

**What it does:**
- Creates `android/app/keystore.jks`
- Outputs base64-encoded keystore
- Shows credentials

**Output file created:**
- `.keystore_base64.txt` (keep this file safe!)

---

## Step 2️⃣: Get Base64 Keystore Content

Check if `.keystore_base64.txt` was created:
```bash
cat .keystore_base64.txt
# Copy all the content (it's very long)
```

**Windows PowerShell alternative:**
```powershell
$b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes('android\app\keystore.jks'))
$b64 | Set-Clipboard
# The content is now in your clipboard!
```

---

## Step 3️⃣: Add GitHub Secrets (2 minutes)

Open in your browser:
```
https://github.com/BeanieMal6336/medidor-emocional---indeia2/settings/secrets/actions
```

Click **"New repository secret"** and add these 4:

### Secret #1: KEYSTORE_BASE64
- **Name:** `KEYSTORE_BASE64`
- **Value:** Paste the entire base64 content from `.keystore_base64.txt`

### Secret #2: KEYSTORE_PASSWORD
- **Name:** `KEYSTORE_PASSWORD`
- **Value:** `MindFlow@2024Secure`

### Secret #3: KEY_PASSWORD
- **Name:** `KEY_PASSWORD`
- **Value:** `MindFlow@2024Secure`

### Secret #4: KEY_ALIAS
- **Name:** `KEY_ALIAS`
- **Value:** `mindflow_release_key`

---

## Step 4️⃣: Clean Up Local Keystore

**IMPORTANT**: Remove the keystore file from your computer:

```bash
# macOS/Linux
rm android/app/keystore.jks

# Windows Command Prompt
del android\app\keystore.jks

# Windows PowerShell
Remove-Item android\app\keystore.jks
```

✅ Verify it's in .gitignore:
```bash
grep -i "jks\|keystore" android/.gitignore
# Should show: **/*.jks or similar
```

---

## Step 5️⃣: Test the Workflow (1 minute)

### Option A: Push Changes (Automatic)
```bash
git add .
git commit -m "Setup CI/CD build fix"
git push origin main
```

The workflow will automatically trigger!

### Option B: Manual Trigger
1. Go to: https://github.com/BeanieMal6336/medidor-emocional---indeia2/actions
2. Click **"Build Installers"** workflow
3. Click **"Run workflow"** button
4. Select branch `main`
5. Click **"Run workflow"**

---

## Monitor the Build 👀

1. Go to GitHub Actions
2. Watch the workflow run
3. Check logs in real-time:
   - ✅ Green = success
   - ❌ Red = failed (check logs for details)

**First run:** May take 5-10 minutes (dependencies)
**Subsequent runs:** 2-3 minutes (caching)

---

## Download Artifacts 📦

When build succeeds:

1. Go to the workflow run
2. Scroll to bottom → **Artifacts**
3. Download:
   - `mindflow-android-apk` → APK file
   - `mindflow-windows-x64` → ZIP file

---

## Troubleshooting 🔧

### "Secrets not found" error
→ Check Step 3 - secrets must be added BEFORE workflow runs

### "Keystore decode failed" 
→ Verify KEYSTORE_BASE64 is complete (very long string)

### "Build failed - signing config"
→ Check Step 2 - base64 encoding might be incomplete

### "APK still not building"
→ Read: `BUILD_FIX_README.md` (detailed troubleshooting)

---

## ✅ Success Signs

Build succeeded when you see:
- ✅ Green checkmark on workflow
- ✅ Artifacts available for download
- ✅ APK file: `app-release.apk`
- ✅ Windows ZIP file: `mindflow-windows-x64.zip`

---

## 📚 Full Documentation

For detailed help:
- **Setup**: `BUILD_FIX_README.md`
- **Keystore**: `KEYSTORE_SETUP.md`
- **Technical**: `IMPLEMENTATION_SUMMARY.md`

---

## ⏱️ Time Estimate

| Step | Time |
|------|------|
| Generate keystore | 1-2 min |
| Get base64 | 1 min |
| Add secrets | 1-2 min |
| Clean up | 1 min |
| Test workflow | 5-10 min (first run) |
| **TOTAL** | **~10 minutes** |

---

## 🎉 You're Done!

After these 5 steps:
- ✅ CI/CD pipeline is fully configured
- ✅ Builds will succeed
- ✅ Artifacts will be generated
- ✅ APK and Windows executables ready

Enjoy your fixed builds! 🚀

---

**Questions?** Check BUILD_FIX_README.md for comprehensive help!