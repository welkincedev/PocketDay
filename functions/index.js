/**
 * PocketDay — Cloud Functions
 * Contact Email Dispatcher & Secure Validation Gateway
 * Destination: welkince.dev@gmail.com
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");
const cors = require("cors")({ origin: true });

if (!admin.apps.length) {
  admin.initializeApp();
}

// Fixed Destination Email
const DESTINATION_EMAIL = "welkince.dev@gmail.com";

// In-Memory Rate Limiting: Max 5 submissions per 10 minutes per IP
const rateLimitMap = new Map();
const RATE_LIMIT_WINDOW_MS = 10 * 60 * 1000;
const MAX_REQUESTS_PER_WINDOW = 5;

function isRateLimited(ip) {
  const now = Date.now();
  const record = rateLimitMap.get(ip);
  if (!record) {
    rateLimitMap.set(ip, { count: 1, firstRequestTime: now });
    return false;
  }
  if (now - record.firstRequestTime > RATE_LIMIT_WINDOW_MS) {
    rateLimitMap.set(ip, { count: 1, firstRequestTime: now });
    return false;
  }
  record.count += 1;
  return record.count > MAX_REQUESTS_PER_WINDOW;
}

// Cleanup stale IP rate limits every 15 minutes
const cleanupTimer = setInterval(() => {
  const now = Date.now();
  for (const [ip, record] of rateLimitMap.entries()) {
    if (now - record.firstRequestTime > RATE_LIMIT_WINDOW_MS) {
      rateLimitMap.delete(ip);
    }
  }
}, 15 * 60 * 1000);
if (cleanupTimer.unref) {
  cleanupTimer.unref();
}

// Basic HTML and Text Sanitization
function sanitize(str) {
  if (typeof str !== "string") return "";
  return str
    .replace(/<[^>]*>/g, "") // strip HTML tags
    .replace(/[<>'"&]/g, (char) => {
      switch (char) {
        case "<": return "&lt;";
        case ">": return "&gt;";
        case "'": return "&#39;";
        case '"': return "&quot;";
        case "&": return "&amp;";
        default: return char;
      }
    })
    .trim();
}

// Email Regex Validator (RFC 5322 standard compliant subset)
function isValidEmail(email) {
  const re = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/;
  return typeof email === "string" && re.test(email.trim()) && email.length <= 100;
}

// Create Nodemailer Transporter based on available environment variables
function getTransporter() {
  const gmailUser = process.env.GMAIL_USER || process.env.SMTP_USER;
  const gmailPass = process.env.GMAIL_APP_PASSWORD || process.env.SMTP_PASS;

  if (gmailUser && gmailPass) {
    return nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: gmailUser,
        pass: gmailPass,
      },
    });
  }

  const smtpHost = process.env.SMTP_HOST;
  const smtpPort = process.env.SMTP_PORT || 587;

  if (smtpHost && gmailUser && gmailPass) {
    return nodemailer.createTransport({
      host: smtpHost,
      port: Number(smtpPort),
      secure: Number(smtpPort) === 465,
      auth: {
        user: gmailUser,
        pass: gmailPass,
      },
    });
  }

  return null;
}

/**
 * HTTPS Endpoint: sendContactEmail
 */
exports.sendContactEmail = functions.https.onRequest((req, res) => {
  return cors(req, res, async () => {
    // Only accept POST requests
    if (req.method !== "POST") {
      return res.status(405).json({
        success: false,
        error: "Method Not Allowed. Please use POST.",
      });
    }

    // IP Extraction for Rate Limiting
    const clientIp =
      req.headers["x-forwarded-for"] ||
      req.connection.remoteAddress ||
      req.socket.remoteAddress ||
      "unknown";

    if (isRateLimited(clientIp)) {
      return res.status(429).json({
        success: false,
        error: "Too many contact submissions from your IP. Please try again in 10 minutes.",
      });
    }

    const { name, email, subject, message, website_url_hp } = req.body || {};

    // 1. Anti-Spam Honeypot Check
    if (website_url_hp && website_url_hp.trim() !== "") {
      console.warn(`Spam bot submission caught by honeypot from IP: ${clientIp}`);
      return res.status(400).json({
        success: false,
        error: "Invalid submission.",
      });
    }

    // 2. Input Validation
    const cleanName = sanitize(name);
    const cleanEmail = (email || "").trim();
    const cleanSubject = sanitize(subject) || "General Inquiry";
    const cleanMessage = sanitize(message);

    if (!cleanName || cleanName.length < 2 || cleanName.length > 100) {
      return res.status(400).json({
        success: false,
        error: "Please provide a valid name (2-100 characters).",
      });
    }

    if (!isValidEmail(cleanEmail)) {
      return res.status(400).json({
        success: false,
        error: "Please provide a valid email address.",
      });
    }

    if (!cleanMessage || cleanMessage.length < 5 || cleanMessage.length > 3000) {
      return res.status(400).json({
        success: false,
        error: "Message must be between 5 and 3000 characters.",
      });
    }

    // 3. Email Delivery Configuration
    const transporter = getTransporter();

    if (!transporter) {
      console.error(
        "PocketDay Email Service Notice: No SMTP / Gmail credentials configured in environment variables (GMAIL_USER, GMAIL_APP_PASSWORD, or SMTP_HOST)."
      );
      return res.status(503).json({
        success: false,
        error:
          "Email delivery service is currently pending SMTP credential configuration. Please configure GMAIL_APP_PASSWORD or SMTP credentials.",
        configured: false,
      });
    }

    // 4. Construct Email Payload
    const mailOptions = {
      from: `"PocketDay Web Contact" <${process.env.GMAIL_USER || process.env.SMTP_USER || DESTINATION_EMAIL}>`,
      to: DESTINATION_EMAIL,
      replyTo: cleanEmail,
      subject: `[PocketDay Inquiry] ${cleanSubject} — from ${cleanName}`,
      text: `You have received a new contact submission from PocketDay Website:

Sender Name: ${cleanName}
Sender Email: ${cleanEmail}
Category / Subject: ${cleanSubject}
IP Address: ${clientIp}
Submitted At: ${new Date().toISOString()}

Message:
--------------------------------------------------
${cleanMessage}
--------------------------------------------------

* You can reply directly to this email to respond to ${cleanEmail}.`,
      html: `
        <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 24px; border: 1px solid #E2E8F0; border-radius: 12px; background-color: #FFFFFF;">
          <div style="border-bottom: 2px solid #10B981; padding-bottom: 16px; margin-bottom: 20px;">
            <h2 style="color: #0F172A; margin: 0; font-size: 20px;">PocketDay Contact Submission</h2>
            <p style="color: #64748B; margin: 4px 0 0 0; font-size: 13px;">New message via PocketDay official public website</p>
          </div>

          <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px; font-size: 14px;">
            <tr>
              <td style="padding: 8px 0; color: #64748B; width: 120px;"><strong>Sender Name:</strong></td>
              <td style="padding: 8px 0; color: #0F172A;">${cleanName}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #64748B;"><strong>Sender Email:</strong></td>
              <td style="padding: 8px 0; color: #0F172A;"><a href="mailto:${cleanEmail}" style="color: #10B981; text-decoration: none;">${cleanEmail}</a></td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #64748B;"><strong>Category:</strong></td>
              <td style="padding: 8px 0; color: #0F172A;">${cleanSubject}</td>
            </tr>
            <tr>
              <td style="padding: 8px 0; color: #64748B;"><strong>Received At:</strong></td>
              <td style="padding: 8px 0; color: #0F172A;">${new Date().toLocaleString("en-US", { timeZone: "Asia/Kolkata" })} IST</td>
            </tr>
          </table>

          <div style="background-color: #F8FAFC; border: 1px solid #E2E8F0; border-radius: 8px; padding: 16px; margin-bottom: 24px;">
            <h4 style="margin: 0 0 8px 0; color: #475569; font-size: 12px; text-transform: uppercase; letter-spacing: 0.05em;">Message Body:</h4>
            <p style="margin: 0; color: #1E293B; font-size: 14px; line-height: 1.6; white-space: pre-wrap;">${cleanMessage}</p>
          </div>

          <div style="border-top: 1px solid #E2E8F0; padding-top: 16px; font-size: 12px; color: #94A3B8; text-align: center;">
            <p style="margin: 0;">This email was sent to <strong>${DESTINATION_EMAIL}</strong>. Simply click "Reply" to respond directly to ${cleanEmail}.</p>
          </div>
        </div>
      `,
    };

    // 5. Send Email via Transporter
    try {
      const info = await transporter.sendMail(mailOptions);
      console.log(`Email successfully dispatched to ${DESTINATION_EMAIL}. MessageId: ${info.messageId}`);
      return res.status(200).json({
        success: true,
        message: `Your message has been delivered to ${DESTINATION_EMAIL}.`,
        messageId: info.messageId,
      });
    } catch (err) {
      console.error("Error dispatching contact email:", err.message);
      return res.status(500).json({
        success: false,
        error: "Failed to send email due to an upstream server error. Please try again later.",
      });
    }
  });
});
