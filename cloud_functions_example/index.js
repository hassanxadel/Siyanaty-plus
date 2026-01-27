/**
 * Firebase Cloud Function for Sending Verification Emails
 * 
 * Setup:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Login: firebase login
 * 3. Initialize: firebase init functions
 * 4. Copy this file to functions/index.js
 * 5. Install dependencies: cd functions && npm install
 * 6. Deploy: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

/**
 * Email Configuration
 * 
 * For Gmail:
 * 1. Enable 2-Step Verification in your Google Account
 * 2. Generate App Password: https://myaccount.google.com/apppasswords
 * 3. Use the app password below (not your regular password)
 * 
 * For Outlook/Hotmail:
 * - Use your regular email and password
 * 
 * For custom SMTP:
 * - Replace with your SMTP server details
 */

// Create email transporter
// Option 1: Gmail
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'your-email@gmail.com', // Replace with your email
    pass: 'your-app-password' // Replace with App Password (not regular password)
  }
});

// Option 2: Outlook/Hotmail
// const transporter = nodemailer.createTransport({
//   service: 'hotmail',
//   auth: {
//     user: 'your-email@outlook.com',
//     pass: 'your-password'
//   }
// });

// Option 3: Custom SMTP Server
// const transporter = nodemailer.createTransport({
//   host: 'smtp.your-domain.com',
//   port: 587,
//   secure: false, // true for 465, false for other ports
//   auth: {
//     user: 'your-email@your-domain.com',
//     pass: 'your-password'
//   }
// });

/**
 * Send Verification Email
 * 
 * HTTP Endpoint that sends verification email with code
 * 
 * Request Body:
 * {
 *   "email": "user@example.com",
 *   "code": "123456",
 *   "userName": "John Doe" (optional)
 * }
 */
exports.sendVerificationEmail = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set('Access-Control-Allow-Origin', '*');
  
  if (req.method === 'OPTIONS') {
    res.set('Access-Control-Allow-Methods', 'POST');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    res.status(204).send('');
    return;
  }

  try {
    // Get request data
    const { email, code, userName } = req.body;

    // Validate input
    if (!email || !code) {
      return res.status(400).json({
        success: false,
        error: 'Email and code are required'
      });
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid email format'
      });
    }

    // Validate code format (6 digits)
    if (!/^\d{6}$/.test(code)) {
      return res.status(400).json({
        success: false,
        error: 'Code must be 6 digits'
      });
    }

    // Create email template
    const htmlTemplate = `
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background-color: #f4f4f4;
      margin: 0;
      padding: 20px;
    }
    .container {
      background-color: white;
      border-radius: 10px;
      padding: 40px;
      max-width: 600px;
      margin: 0 auto;
      box-shadow: 0 4px 15px rgba(0,0,0,0.1);
    }
    .header {
      text-align: center;
      color: #062117;
      margin-bottom: 30px;
    }
    .logo {
      font-size: 48px;
      margin-bottom: 10px;
    }
    .title {
      font-size: 28px;
      font-weight: bold;
      margin: 0;
    }
    .subtitle {
      font-size: 18px;
      color: #666;
      margin-top: 5px;
    }
    .content {
      line-height: 1.6;
      color: #333;
      font-size: 16px;
    }
    .code-box {
      background: linear-gradient(135deg, #062117 0%, #0a3326 100%);
      color: white;
      font-size: 40px;
      font-weight: bold;
      text-align: center;
      padding: 30px;
      border-radius: 12px;
      letter-spacing: 12px;
      margin: 30px 0;
      box-shadow: 0 4px 10px rgba(6, 33, 23, 0.3);
    }
    .info {
      background-color: #f8f9fa;
      border-left: 4px solid #062117;
      padding: 15px;
      margin: 20px 0;
      border-radius: 4px;
    }
    .footer {
      color: #666;
      font-size: 14px;
      text-align: center;
      margin-top: 40px;
      padding-top: 20px;
      border-top: 2px solid #eee;
    }
    .warning {
      color: #ff6b6b;
      font-size: 13px;
      text-align: center;
      margin-top: 15px;
      font-weight: bold;
    }
    .button {
      display: inline-block;
      background-color: #062117;
      color: white;
      padding: 12px 30px;
      text-decoration: none;
      border-radius: 6px;
      margin-top: 20px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div class="logo">🚗</div>
      <h1 class="title">Siyanaty</h1>
      <p class="subtitle">Your Car Maintenance Companion</p>
    </div>
    
    <div class="content">
      <p>Hello ${userName || 'there'},</p>
      <p>You requested a verification code to access your Siyanaty account. Please use the code below to continue:</p>
      
      <div class="code-box">${code}</div>
      
      <div class="info">
        <strong>⏰ Important:</strong> This code will expire in <strong>5 minutes</strong>. 
        Please enter it in the app as soon as possible.
      </div>
      
      <p>If you didn't request this code, please ignore this email. Your account remains secure.</p>
    </div>
    
    <div class="footer">
      <p><strong>© ${new Date().getFullYear()} Siyanaty</strong></p>
      <p>Smart Car Maintenance & Management</p>
      <p class="warning">⚠️ Never share this code with anyone</p>
    </div>
  </div>
</body>
</html>
    `;

    // Plain text version for email clients that don't support HTML
    const textTemplate = `
Hello ${userName || 'there'},

Your verification code for Siyanaty is: ${code}

This code will expire in 5 minutes.

If you didn't request this code, please ignore this email.

© ${new Date().getFullYear()} Siyanaty - Your Car Maintenance Companion
Never share this code with anyone.
    `;

    // Configure email options
    const mailOptions = {
      from: {
        name: 'Siyanaty',
        address: 'noreply@siyanaty.app' // Change to your domain
      },
      to: email,
      subject: `${code} is your Siyanaty verification code`,
      text: textTemplate,
      html: htmlTemplate
    };

    // Send email
    console.log(`Sending verification email to ${email} with code ${code}`);
    await transporter.sendMail(mailOptions);
    
    console.log(`Verification email sent successfully to ${email}`);
    
    // Return success response
    return res.status(200).json({
      success: true,
      message: 'Verification email sent successfully'
    });

  } catch (error) {
    console.error('Error sending verification email:', error);
    
    return res.status(500).json({
      success: false,
      error: 'Failed to send verification email',
      details: error.message
    });
  }
});

/**
 * Alternative: Firestore Trigger
 * 
 * This function automatically sends email when a document is created
 * in the 'verification_emails' collection
 * 
 * Usage in Flutter:
 * await FirebaseFirestore.instance.collection('verification_emails').add({
 *   'email': email,
 *   'code': code,
 *   'userName': userName,
 *   'timestamp': FieldValue.serverTimestamp(),
 * });
 */
exports.sendVerificationEmailTrigger = functions.firestore
  .document('verification_emails/{emailId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const { email, code, userName } = data;

    try {
      const htmlTemplate = `
        <!DOCTYPE html>
        <html>
        <body style="font-family: Arial, sans-serif;">
          <h2>Verification Code</h2>
          <p>Hello ${userName || 'there'},</p>
          <p>Your verification code is:</p>
          <h1 style="background: #062117; color: white; padding: 20px; text-align: center; letter-spacing: 8px;">
            ${code}
          </h1>
          <p>This code expires in 5 minutes.</p>
        </body>
        </html>
      `;

      await transporter.sendMail({
        from: 'Siyanaty <noreply@siyanaty.app>',
        to: email,
        subject: `${code} is your verification code`,
        html: htmlTemplate
      });

      // Mark email as sent
      await snap.ref.update({ sent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });
      
      console.log(`Verification email sent to ${email}`);
    } catch (error) {
      console.error('Error sending email:', error);
      await snap.ref.update({ error: error.message });
    }
  });

/**
 * Test Endpoint
 * 
 * Send a GET request to test if the function is working
 * URL: https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/testEmail
 */
exports.testEmail = functions.https.onRequest((req, res) => {
  res.json({
    status: 'Cloud Functions are working!',
    timestamp: new Date().toISOString()
  });
});

