# Siyanaty+ Security User Guide

## Welcome to Secure Car Maintenance! 🚗🔒

Your Siyanaty+ app now includes advanced security features to protect your personal information and vehicle data. This guide will help you understand and use these features.

---

## 🎯 What's New?

After updating to the latest version, you'll notice these security improvements:

1. **PIN Protection** - Quick 4-6 digit code to unlock the app
2. **Fingerprint/Face ID** - Even faster unlock with biometrics
3. **Auto-Lock** - App locks when you switch to other apps
4. **Two-Factor Authentication** - Extra security when logging in from new devices
5. **Encrypted Data** - All your car and maintenance data is encrypted

---

## 📱 First Time Setup

### Step 1: Log In
- Enter your email and password as usual
- If logging in from a new device, you'll receive a verification code via SMS

### Step 2: Create Your PIN
After your first successful login, you'll see the PIN setup screen:

```
┌─────────────────────────────────┐
│         Set Up PIN              │
│                                 │
│  Create a 4-6 digit PIN to      │
│  secure your app                │
│                                 │
│        ● ● ● ● ○ ○              │
│                                 │
│     [Numeric Keypad]            │
│                                 │
└─────────────────────────────────┘
```

**To create your PIN:**
1. Tap numbers to enter a 4-6 digit PIN
2. Tap the checkmark when done
3. Re-enter the same PIN to confirm
4. Done! Your PIN is now set

**PIN Tips:**
- ✅ Choose a PIN you'll remember
- ✅ Don't use obvious numbers like 1234 or your birth year
- ✅ Make it at least 5 digits for better security
- ❌ Never share your PIN with anyone

### Step 3: Enable Biometrics (Optional but Recommended)
After setting your PIN, you'll be asked:

```
┌─────────────────────────────────┐
│   Enable Biometric              │
│   Authentication?               │
│                                 │
│      [Fingerprint Icon]         │
│                                 │
│  Use your fingerprint or face   │
│  for faster unlock              │
│                                 │
│   [Enable]      [Skip]          │
└─────────────────────────────────┘
```

**Recommended:** Tap "Enable" for the fastest unlock experience!

---

## 🔓 Daily Use

### Opening the App

Every time you open Siyanaty+, you'll see the unlock screen:

**If Biometrics Enabled:**
```
┌─────────────────────────────────┐
│      [App Logo]                 │
│                                 │
│     Welcome Back!               │
│                                 │
│   [Fingerprint Icon]            │
│                                 │
│  Touch the fingerprint sensor   │
│                                 │
│     [Use PIN instead]           │
└─────────────────────────────────┘
```

Just touch your fingerprint sensor or look at your phone for Face ID!

**If Using PIN:**
```
┌─────────────────────────────────┐
│      [App Logo]                 │
│                                 │
│     Enter Your PIN              │
│                                 │
│        ● ● ● ● ○ ○              │
│                                 │
│     [Numeric Keypad]            │
│                                 │
│     [Forgot PIN?]               │
└─────────────────────────────────┘
```

Enter your PIN and tap the checkmark!

### Auto-Lock Feature

The app automatically locks when you:
- Switch to another app
- Press the home button
- Turn off your screen
- Leave the app idle for too long

This protects your data if someone else picks up your phone.

---

## 🔐 Security Features Explained

### 1. PIN Protection

**What it is:** A 4-6 digit code that unlocks the app

**Why it's secure:**
- Your PIN is never stored in plain text
- It's encrypted using military-grade encryption
- Even if someone accesses your phone's files, they can't see your PIN

**What happens if you enter the wrong PIN:**
- You have 5 attempts
- After 5 wrong attempts, you'll need to log in again with your email and password

### 2. Biometric Authentication

**What it is:** Using your fingerprint or face to unlock the app

**Why it's secure:**
- Your biometric data never leaves your phone
- It's stored in a secure chip in your device
- Even Siyanaty+ can't access your actual fingerprint or face data

**Supported:**
- ✅ Fingerprint (Android & iOS)
- ✅ Face ID (iOS)
- ✅ Face Recognition (Android)

### 3. Two-Factor Authentication (MFA)

**What it is:** An extra verification step when logging in from a new device

**When you'll see it:**
- First time logging in from a new phone
- After reinstalling the app
- When logging in from a device we don't recognize

**How it works:**
```
1. You log in with email/password
2. We send a 6-digit code to your phone via SMS
3. You enter the code in the app
4. Your device is now trusted
```

**Trusted Devices:**
- Once verified, you won't need the code again on that device
- You can view and remove trusted devices in Settings

### 4. Encrypted Data

**What it is:** All your data is scrambled so only you can read it

**What's encrypted:**
- ✅ Your car information
- ✅ Maintenance records
- ✅ Service reminders
- ✅ Personal notes
- ✅ Photos and documents

**Why it matters:**
- Even if someone steals your phone, they can't read your data
- Your information is safe even if you lose your device

---

## ⚙️ Managing Your Security

### Accessing Security Settings

1. Open Siyanaty+
2. Tap the **Settings** tab (bottom right)
3. Scroll to **Security** section

### Available Options:

#### Change PIN
```
Settings → Security → Change PIN
```
1. Enter your current PIN
2. Enter your new PIN
3. Confirm your new PIN
4. Done!

#### Enable/Disable Biometrics
```
Settings → Security → Biometric Authentication
```
Toggle the switch to turn biometrics on or off

#### View Trusted Devices
```
Settings → Security → Trusted Devices
```
See all devices where you're logged in. Tap any device to:
- View last active time
- See device name
- Remove access (logout remotely)

#### Auto-Lock Settings
```
Settings → Security → Auto-Lock
```
Choose when the app should lock:
- Immediately
- After 1 minute
- After 5 minutes
- After 15 minutes
- Never (not recommended)

---

## 🆘 Troubleshooting

### I Forgot My PIN!

**Don't worry!** Here's what to do:

1. On the unlock screen, tap **"Forgot PIN?"**
2. You'll be taken to the login screen
3. Log in with your email and password
4. If needed, verify with the SMS code
5. You'll be prompted to create a new PIN
6. Done! You're back in with a new PIN

**Note:** Your data is safe! Everything will be exactly as you left it.

### Biometrics Not Working

**Try these steps:**

1. **Make sure biometrics are enabled:**
   - Settings → Security → Biometric Authentication → ON

2. **Check your device settings:**
   - Go to your phone's Settings
   - Find Biometric/Security settings
   - Make sure fingerprint/face is enrolled

3. **Use PIN instead:**
   - On the unlock screen, tap "Use PIN instead"
   - Enter your PIN to access the app

4. **Re-enable biometrics:**
   - Settings → Security → Biometric Authentication
   - Toggle OFF then ON again

### "Too Many Failed Attempts"

If you see this message:

```
┌─────────────────────────────────┐
│     Account Locked              │
│                                 │
│  Too many failed PIN attempts   │
│                                 │
│  Please sign in with your       │
│  email and password             │
│                                 │
│     [Sign In]                   │
└─────────────────────────────────┘
```

**What to do:**
1. Tap "Sign In"
2. Enter your email and password
3. Verify with SMS code if prompted
4. Create a new PIN
5. You're back in!

**Why this happens:**
- Protects your account from unauthorized access
- Prevents someone from guessing your PIN
- Ensures only you can access your data

### Not Receiving SMS Codes

**Try these solutions:**

1. **Check your phone number:**
   - Settings → Profile → Phone Number
   - Make sure it's correct

2. **Check signal:**
   - Make sure you have cellular service
   - SMS codes need mobile network

3. **Wait a moment:**
   - Codes can take up to 60 seconds to arrive

4. **Request a new code:**
   - Tap "Resend Code" on the verification screen

5. **Check spam/blocked:**
   - Some phones block automated SMS
   - Check your messaging app settings

---

## 💡 Security Tips

### Do's ✅

- ✅ **Use a strong PIN** - At least 5 digits, not obvious
- ✅ **Enable biometrics** - Faster and more secure
- ✅ **Keep app updated** - Get latest security improvements
- ✅ **Use a strong password** - For your email/password login
- ✅ **Enable auto-lock** - Protects if you forget to lock
- ✅ **Review trusted devices** - Remove old devices you no longer use

### Don'ts ❌

- ❌ **Don't share your PIN** - Keep it private
- ❌ **Don't use 1234 or 0000** - Too easy to guess
- ❌ **Don't disable security** - Your data needs protection
- ❌ **Don't ignore updates** - Security improvements are important
- ❌ **Don't root/jailbreak** - Weakens device security

---

## 🎓 Understanding Security Levels

### Level 1: Email/Password
- Your first line of defense
- Required for initial login
- Can be reset if forgotten

### Level 2: Two-Factor (SMS)
- Extra verification for new devices
- Proves you have access to your phone
- Prevents unauthorized access

### Level 3: PIN/Biometric
- Quick unlock for daily use
- Protects if someone has your phone
- Fast but secure

### All Together = Maximum Security! 🛡️

With all three levels active:
1. Someone needs your password (something you know)
2. AND your phone for SMS (something you have)
3. AND your PIN or fingerprint (something you are)

This makes it nearly impossible for anyone else to access your account!

---

## 📞 Need Help?

### In-App Support
```
Settings → Help & Support → Security Issues
```

### Common Questions

**Q: Is my data safe?**  
A: Yes! Your data is encrypted with military-grade encryption. Even we can't read it without your PIN.

**Q: Can I use the app without a PIN?**  
A: No, the PIN is required for security. But you can use biometrics for faster unlock!

**Q: What if I get a new phone?**  
A: Just log in with your email/password, verify with SMS, and set up a new PIN. Your data will sync automatically!

**Q: Can someone access my data if they steal my phone?**  
A: No! They would need your PIN or biometric, and after 5 failed attempts, the app locks completely.

**Q: Does biometric authentication work offline?**  
A: Yes! Both PIN and biometric work without internet connection.

---

## 🎉 You're All Set!

Your Siyanaty+ app is now secured with multiple layers of protection. Your car data, maintenance records, and personal information are safe!

**Remember:**
- Use a strong PIN
- Enable biometrics for convenience
- Keep your app updated
- Review your security settings regularly

**Enjoy peace of mind while maintaining your vehicle!** 🚗✨

---

**Last Updated:** November 1, 2025  
**App Version:** 1.0.0 with Security Features  
**Questions?** Contact support through the app's Help section

