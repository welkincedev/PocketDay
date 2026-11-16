/**
 * PocketDay — Contact Form Controller
 * Destination: welkince.dev@gmail.com
 */

document.addEventListener('DOMContentLoaded', () => {
  const contactForm = document.getElementById('contactForm');
  const formSuccess = document.getElementById('contactFormSuccess');
  const formError = document.getElementById('contactFormError');
  const submitBtn = document.getElementById('contactSubmitBtn');
  const sendAnotherBtn = document.getElementById('sendAnotherMessageBtn');

  function showError(msg) {
    if (formError) {
      formError.innerHTML = msg;
      formError.style.display = 'block';
      formError.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
  }

  function hideError() {
    if (formError) {
      formError.style.display = 'none';
      formError.innerHTML = '';
    }
  }

  // Email Regex validation
  function isValidEmail(email) {
    const re = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$/;
    return re.test(String(email).toLowerCase().trim());
  }

  if (contactForm) {
    contactForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      hideError();

      // 1. Anti-spam honeypot
      const honeypot = document.getElementById('website_url_hp');
      if (honeypot && honeypot.value.trim() !== '') {
        console.warn('PocketDay: Automated bot submission blocked.');
        return;
      }

      // 2. Input values
      const nameInput = document.getElementById('contactName');
      const emailInput = document.getElementById('contactEmail');
      const categoryInput = document.getElementById('contactCategory');
      const messageInput = document.getElementById('contactMessage');

      const name = (nameInput ? nameInput.value : '').trim();
      const email = (emailInput ? emailInput.value : '').trim();
      const subject = (categoryInput ? categoryInput.value : 'General Inquiry').trim();
      const message = (messageInput ? messageInput.value : '').trim();

      // 3. Client Validation
      if (!name || name.length < 2) {
        showError('Please enter your full name (minimum 2 characters).');
        if (nameInput) nameInput.focus();
        return;
      }

      if (!email || !isValidEmail(email)) {
        showError('Please enter a valid email address so we can reply to you.');
        if (emailInput) emailInput.focus();
        return;
      }

      if (!message || message.length < 5) {
        showError('Please write a message with at least 5 characters.');
        if (messageInput) messageInput.focus();
        return;
      }

      // 4. Prevent duplicate clicks & show loading state
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.innerHTML = `
          <span style="display:inline-block; width:14px; height:14px; border:2px solid #ffffff; border-radius:50%; border-top-color:transparent; animation:spin 0.6s linear infinite; margin-right:8px; vertical-align:middle;"></span>
          Sending Message...
        `;
      }

      // Disable inputs while sending
      const formElements = contactForm.querySelectorAll('input, select, textarea');
      formElements.forEach((el) => (el.disabled = true));

      try {
        // Determine backend endpoint
        // Local preview runs on :8085; Cloud Function endpoint on /api/sendContactEmail
        const endpoint = '/api/sendContactEmail';

        const payload = {
          name,
          email,
          subject,
          message,
          website_url_hp: honeypot ? honeypot.value : '',
        };

        const response = await fetch(endpoint, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: JSON.stringify(payload),
        });

        let data = null;
        try {
          data = await response.json();
        } catch (_) {
          data = null;
        }

        if (response.ok && data && data.success) {
          // Success: Deliver confirmation
          contactForm.style.display = 'none';
          if (formSuccess) formSuccess.style.display = 'block';
        } else {
          // Server error or credentials unconfigured
          let errorMsg = 'Failed to send message. Please try again later.';
          if (data && data.error) {
            errorMsg = data.error;
          } else if (response.status === 404) {
            // Function endpoint not deployed yet
            errorMsg = `
              <strong>Backend Notice:</strong> The server-side email dispatch function is not yet deployed on this host. 
              <br><br>
              You can send your message directly to: <br>
              <a href="mailto:welkince.dev@gmail.com?subject=${encodeURIComponent('[PocketDay] ' + subject)}&body=${encodeURIComponent(message)}" style="color: #10B981; font-weight: bold; text-decoration: underline;">
                welkince.dev@gmail.com
              </a>
            `;
          } else if (response.status === 503) {
            errorMsg = `
              <strong>Email Service Notice:</strong> Server email credentials (SMTP/Gmail App Password) are currently pending configuration on the server.
              <br><br>
              Direct contact is available at: <a href="mailto:welkince.dev@gmail.com" style="color: #10B981; text-decoration: underline; font-weight: bold;">welkince.dev@gmail.com</a>
            `;
          }
          showError(errorMsg);
        }
      } catch (networkErr) {
        console.error('PocketDay contact submission error:', networkErr);
        showError(`
          Network error: Could not reach the server endpoint.
          <br><br>
          Please email directly to: 
          <a href="mailto:welkince.dev@gmail.com?subject=${encodeURIComponent('[PocketDay] ' + subject)}&body=${encodeURIComponent(message)}" style="color: #10B981; font-weight: bold; text-decoration: underline;">
            welkince.dev@gmail.com
          </a>
        `);
      } finally {
        if (submitBtn) {
          submitBtn.disabled = false;
          submitBtn.textContent = 'Send Message';
        }
        formElements.forEach((el) => (el.disabled = false));
      }
    });
  }

  // Handle "Send Another Message"
  if (sendAnotherBtn) {
    sendAnotherBtn.addEventListener('click', () => {
      if (contactForm) {
        contactForm.reset();
        contactForm.style.display = 'block';
      }
      if (formSuccess) formSuccess.style.display = 'none';
      hideError();
    });
  }
});
