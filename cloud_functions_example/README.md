# 🔥 Firebase Cloud Functions for Email Verification

This directory contains Firebase Cloud Functions for sending verification emails.

## 📋 Prerequisites

1. **Node.js** (v18 or higher)
2. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```
3. **Firebase Project** with Blaze (Pay-as-you-go) plan
   - Required for outbound network requests (sending emails)

## 🚀 Setup Instructions

### Step 1: Initialize Firebase Functions

```bash
# Login to Firebase
firebase login

# Initialize Functions in your project
cd your_project_directory
firebase init functions
```

When prompted:
- Select **JavaScript** or **TypeScript**
- Install dependencies: **Yes**

### Step 2: Copy Files

Copy these files to your `functions/` directory:
```bash
# From cloud_functions_example/ to functions/
cp cloud_functions_example/index.js functions/index.js
cp cloud_functions_example/package.json functions/package.json
```

### Step 3: Configure Email Service

Edit `functions/index.js` and update the email configuration:

#### For Gmail:
```javascript
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'your-email@gmail.com',
    pass: 'your-app-password' // Generate at: myaccount.google.com/apppasswords
  }
});
```

**Gmail Setup:**
1. Enable 2-Step Verification: https://myaccount.google.com/security
2. Generate App Password: https://myaccount.google.com/apppasswords
3. Use the 16-character app password (not your regular password)

#### For Outlook/Hotmail:
```javascript
const transporter = nodemailer.createTransport({
  service: 'hotmail',
  auth: {
    user: 'your-email@outlook.com',
    pass: 'your-password'
  }
});
```

#### For Custom SMTP:
```javascript
const transporter = nodemailer.createTransport({
  host: 'smtp.yourdomain.com',
  port: 587,
  secure: false,
  auth: {
    user: 'your-email@yourdomain.com',
    pass: 'your-password'
  }
});
```

### Step 4: Install Dependencies

```bash
cd functions
npm install
```

### Step 5: Test Locally (Optional)

```bash
# Start emulator
firebase emulators:start --only functions

# In another terminal, test the endpoint
curl http://localhost:5001/YOUR_PROJECT/us-central1/sendVerificationEmail \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","code":"123456","userName":"Test User"}'
```

### Step 6: Deploy

```bash
# Deploy all functions
firebase deploy --only functions

# Or deploy specific function
firebase deploy --only functions:sendVerificationEmail
```

## 📱 Integrate with Flutter App

### Option 1: HTTP Endpoint (Recommended)

After deployment, you'll get a URL like:
```
https://us-central1-YOUR_PROJECT.cloudfunctions.net/sendVerificationEmail
```

Update `lib/services/security/authentication_manager.dart`:

```dart
// Uncomment and update the cloud function URL (around line 271)
final cloudFunctionUrl = 'https://us-central1-YOUR_PROJECT.cloudfunctions.net/sendVerificationEmail';
final response = await http.post(
  Uri.parse(cloudFunctionUrl),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'email': email,
    'code': code,
    'userName': userName ?? 'User',
  }),
);

if (response.statusCode == 200) {
  AppLogger.info('Verification email sent successfully to $email');
  return true;
}
```

### Option 2: Firestore Trigger

If you prefer Firestore triggers, use `sendVerificationEmailTrigger`:

```dart
// In your Flutter app
await FirebaseFirestore.instance.collection('verification_emails').add({
  'email': email,
  'code': code,
  'userName': userName,
  'timestamp': FieldValue.serverTimestamp(),
});

// The cloud function will automatically send the email
```

## 🔍 Monitoring & Logs

### View Logs
```bash
# Real-time logs
firebase functions:log

# Or in Firebase Console
# Functions → Logs tab
```

### Test Endpoint
Visit this URL in your browser to check if functions are working:
```
https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/testEmail
```

## 💰 Pricing

Firebase Cloud Functions (Blaze Plan):
- **Free tier**: 2M invocations/month
- **After free tier**: $0.40 per million invocations
- **Outbound networking**: $0.12 per GB

Email sending costs (using Gmail/Outlook): **FREE** ✅

**Estimated costs for 10,000 users:**
- 10,000 verification emails/month ≈ $0.004
- Practically **FREE** for most apps!

## 🔒 Security Best Practices

1. **Never commit credentials** to Git
   ```bash
   # Add to .gitignore
   functions/.env
   ```

2. **Use Environment Variables**
   ```bash
   firebase functions:config:set email.user="your-email@gmail.com"
   firebase functions:config:set email.pass="your-app-password"
   ```
   
   Then in code:
   ```javascript
   const config = functions.config();
   auth: {
     user: config.email.user,
     pass: config.email.pass
   }
   ```

3. **Add Rate Limiting** (prevent abuse)
   ```javascript
   // Check if user has requested too many codes
   const recentRequests = await admin.firestore()
     .collection('verification_requests')
     .where('email', '==', email)
     .where('timestamp', '>', Date.now() - 3600000) // last hour
     .get();
   
   if (recentRequests.size >= 3) {
     return res.status(429).json({ error: 'Too many requests' });
   }
   ```

4. **Validate Requests** (check if user is authenticated)
   ```javascript
   const token = req.headers.authorization?.split('Bearer ')[1];
   const decodedToken = await admin.auth().verifyIdToken(token);
   ```

## 🐛 Troubleshooting

### Error: "Billing account not configured"
- Upgrade to Blaze plan in Firebase Console
- Free tier available (2M invocations/month)

### Error: "Invalid login: 535-5.7.8 Username and Password not accepted"
- For Gmail: Use App Password, not regular password
- Enable "Less secure app access" for other providers

### Error: "ECONNREFUSED"
- Check SMTP server and port
- Verify firewall/network settings

### Emails going to spam
- Use a verified domain
- Set up SPF and DKIM records
- Use proper "from" address

### Function timing out
- Increase timeout in Firebase Console (default: 60s)
- Or in code:
  ```javascript
  exports.sendEmail = functions.runWith({
    timeoutSeconds: 120
  }).https.onRequest(...)
  ```

## 📚 Additional Resources

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Nodemailer Documentation](https://nodemailer.com/)
- [Gmail App Passwords](https://support.google.com/accounts/answer/185833)
- [Firebase Functions Pricing](https://firebase.google.com/pricing)

## 🆘 Support

If you encounter issues:
1. Check function logs: `firebase functions:log`
2. Test locally with emulator
3. Verify email credentials
4. Check Firebase Console for errors

---

Happy Coding! 🚀

