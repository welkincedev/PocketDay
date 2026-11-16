/**
 * Automated Test Suite for PocketDay Contact Function
 */

const assert = require("assert");
const nodemailer = require("nodemailer");

// Store sent mail records for assertion
const sentMails = [];

// Mock nodemailer.createTransport
nodemailer.createTransport = function (config) {
  return {
    sendMail: async function (options) {
      sentMails.push(options);
      return { messageId: "mock-msg-id-" + Date.now() };
    },
  };
};

process.env.GMAIL_USER = "welkince.dev@gmail.com";
process.env.GMAIL_APP_PASSWORD = "test-app-password";

// Load function after mocking
const { sendContactEmail } = require("./index.js");

function createMockReqRes(options = {}) {
  const req = {
    method: options.method || "POST",
    headers: {
      "x-forwarded-for": options.ip || "192.168.1.100",
      ...(options.headers || {}),
    },
    body: options.body || {},
  };

  let statusCode = 200;
  let responseData = null;

  const res = {
    status(code) {
      statusCode = code;
      return res;
    },
    json(data) {
      responseData = data;
      return res;
    },
    setHeader() {},
    getHeader() {},
  };

  return { req, res, getStatus: () => statusCode, getData: () => responseData };
}

async function runTests() {
  console.log("=== Running PocketDay Contact Function Test Suite ===");
  let passed = 0;
  let failed = 0;

  // Test 1: Reject non-POST methods
  {
    const { req, res, getStatus, getData } = createMockReqRes({ method: "GET" });
    await sendContactEmail(req, res);
    assert.strictEqual(getStatus(), 405, "Expected 405 Method Not Allowed");
    assert.strictEqual(getData().success, false);
    console.log("✓ Test 1 Passed: Rejects non-POST methods (405)");
    passed++;
  }

  // Test 2: Reject spam honeypot
  {
    const { req, res, getStatus, getData } = createMockReqRes({
      body: {
        name: "Bot Spammer",
        email: "spammer@bot.com",
        message: "Check this link",
        website_url_hp: "http://spam-link.com",
      },
    });
    await sendContactEmail(req, res);
    assert.strictEqual(getStatus(), 400, "Expected 400 for honeypot triggered");
    assert.strictEqual(getData().success, false);
    console.log("✓ Test 2 Passed: Honeypot catches bot submissions (400)");
    passed++;
  }

  // Test 3: Reject invalid email format
  {
    const { req, res, getStatus, getData } = createMockReqRes({
      body: {
        name: "John Doe",
        email: "not-an-email",
        message: "Hello there, need help.",
      },
    });
    await sendContactEmail(req, res);
    assert.strictEqual(getStatus(), 400, "Expected 400 for invalid email");
    assert.strictEqual(getData().success, false);
    console.log("✓ Test 3 Passed: Rejects invalid email format (400)");
    passed++;
  }

  // Test 4: Reject short message (< 5 chars)
  {
    const { req, res, getStatus, getData } = createMockReqRes({
      body: {
        name: "Jane Doe",
        email: "jane@example.com",
        message: "Hi",
      },
    });
    await sendContactEmail(req, res);
    assert.strictEqual(getStatus(), 400, "Expected 400 for message < 5 chars");
    assert.strictEqual(getData().success, false);
    console.log("✓ Test 4 Passed: Rejects undersized messages (400)");
    passed++;
  }

  // Test 5: Reject empty/short name
  {
    const { req, res, getStatus, getData } = createMockReqRes({
      body: {
        name: "A",
        email: "user@example.com",
        message: "Valid message length here.",
      },
    });
    await sendContactEmail(req, res);
    assert.strictEqual(getStatus(), 400, "Expected 400 for name < 2 chars");
    assert.strictEqual(getData().success, false);
    console.log("✓ Test 5 Passed: Rejects invalid name (400)");
    passed++;
  }

  // Test 6: Valid Submission Verification (Email destination, replyTo, sanitization)
  {
    sentMails.length = 0;
    const { req, res, getStatus, getData } = createMockReqRes({
      ip: "10.0.0.1",
      body: {
        name: "Alice <script>alert(1)</script>",
        email: "alice@example.com",
        subject: "Budget Feature Request",
        message: "Can we have recurring budgets? Thanks!",
      },
    });

    await sendContactEmail(req, res);
    assert.strictEqual(getStatus(), 200, "Expected 200 OK for valid submission");
    assert.strictEqual(getData().success, true);
    assert.strictEqual(sentMails.length, 1, "Expected 1 mail dispatched");

    const mail = sentMails[0];
    assert.strictEqual(mail.to, "welkince.dev@gmail.com", "Destination email must be welkince.dev@gmail.com");
    assert.strictEqual(mail.replyTo, "alice@example.com", "Reply-To must match visitor email");
    assert.ok(mail.subject.includes("Budget Feature Request"), "Subject must contain category/subject");
    assert.ok(!mail.text.includes("<script>"), "Sanitization must strip script tags");
    assert.ok(mail.text.includes("Alice"), "Text must contain sanitized name");
    console.log("✓ Test 6 Passed: Valid submission delivered to welkince.dev@gmail.com with Reply-To set and XSS sanitized (200)");
    passed++;
  }

  // Test 7: Rate Limiting Enforcement (Exceeding max requests)
  {
    const testIp = "203.0.113.42";
    let lastStatus = 200;
    for (let i = 0; i < 7; i++) {
      const { req, res, getStatus } = createMockReqRes({
        ip: testIp,
        body: {
          name: "Test User",
          email: "test@example.com",
          message: "A test inquiry message.",
        },
      });
      await sendContactEmail(req, res);
      lastStatus = getStatus();
    }
    assert.strictEqual(lastStatus, 429, "Expected 429 Too Many Requests after 5 attempts");
    console.log("✓ Test 7 Passed: Rate limiting triggers at request threshold (429)");
    passed++;
  }

  // Test 8: Verify unconfigured credentials produce clean 503 error
  {
    delete process.env.GMAIL_USER;
    delete process.env.SMTP_USER;
    delete process.env.GMAIL_APP_PASSWORD;
    delete process.env.SMTP_PASS;

    const { req, res, getStatus, getData } = createMockReqRes({
      ip: "198.51.100.99",
      body: {
        name: "Valid User",
        email: "valid@example.com",
        subject: "Feature Inquiry",
        message: "This is a legitimate user message.",
      },
    });

    await sendContactEmail(req, res);
    assert.strictEqual(getStatus(), 503, "Expected 503 when SMTP is unconfigured");
    assert.strictEqual(getData().configured, false);
    console.log("✓ Test 8 Passed: Unconfigured credentials gracefully return 503 without crashing");
    passed++;
  }

  console.log(`\n======================================================`);
  console.log(`Test Results: ${passed} passed, ${failed} failed.`);
  console.log(`All contact function verification assertions passed!`);
  console.log(`======================================================\n`);
}

runTests().catch((err) => {
  console.error("Test failed with error:", err);
  process.exit(1);
});
