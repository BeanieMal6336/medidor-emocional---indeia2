# Android Keystore Setup Guide

## Quick Start

Run the keystore generation script:
```bash
python generate_keystore.py
```

This will:
1. Generate `android/app/keystore.jks` 
2. Output secrets for GitHub
3. Create `.keystore_base64.txt` with encoded keystore

## Manual Setup (if script doesn't work)

If you have Java/keytool installed, run:

```bash
keytool -genkey -v \
  -keystore android/app/keystore.jks \
  -keyalg RSA -keysize 2048 -validity 3650 \
  -alias mindflow_release_key \
  -storepass "MindFlow@2024Secure" \
  -keypass "MindFlow@2024Secure" \
  -dname "CN=MindFlow,OU=Development,O=MindFlow,C=BR"
```

## Adding Secrets to GitHub

1. Go to: https://github.com/BeanieMal6336/medidor-emocional---indeia2/settings/secrets/actions
2. Create these 4 secrets:

### 1. KEYSTORE_BASE64
Encode the keystore to base64:
```bash
base64 -i android/app/keystore.jks -o /tmp/keystore.txt
# Then copy the entire content from /tmp/keystore.txt
```

### 2. KEYSTORE_PASSWORD
```
MindFlow@2024Secure
```

### 3. KEY_PASSWORD
```
MindFlow@2024Secure
```

### 4. KEY_ALIAS
```
mindflow_release_key
```

## Credentials Reference
- **Store Password**: MindFlow@2024Secure
- **Key Password**: MindFlow@2024Secure  
- **Key Alias**: mindflow_release_key
- **Validity**: 10 years (3650 days)
- **Algorithm**: RSA 2048-bit
- **Certificate Name**: MindFlow

## Verification

List keystore contents:
```bash
keytool -list -v -keystore android/app/keystore.jks -storepass MindFlow@2024Secure
```

## Important Notes

⚠️ **DO NOT COMMIT** `android/app/keystore.jks` to Git!
- It's already in `.gitignore` 
- The keystore is sensitive and should only exist in GitHub Secrets
- Remove it locally after encoding to base64