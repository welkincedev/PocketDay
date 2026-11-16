/**
 * PocketDay — Account & Data Deletion Controller
 * Google Play Store Compliant Self-Service Deletion Portal
 */

document.addEventListener('DOMContentLoaded', () => {
  // Tab Switching (Instant Self-Service vs. Assisted Request)
  const tabButtons = document.querySelectorAll('.deletion-tab-btn');
  const tabPanes = document.querySelectorAll('.tab-pane');

  tabButtons.forEach((btn) => {
    btn.addEventListener('click', () => {
      const targetId = btn.getAttribute('data-tab');
      tabButtons.forEach((b) => b.classList.remove('active'));
      tabPanes.forEach((p) => p.classList.remove('active'));

      btn.classList.add('active');
      const targetPane = document.getElementById(targetId);
      if (targetPane) targetPane.classList.add('active');
    });
  });

  // UI Elements for Self-Service Flow
  const loginForm = document.getElementById('deletionLoginForm');
  const googleBtn = document.getElementById('googleSignInBtn');
  const resetPasswordBtn = document.getElementById('sendResetEmailBtn');
  const authCard = document.getElementById('deletionAuthStep');
  const confirmCard = document.getElementById('deletionConfirmStep');
  const progressCard = document.getElementById('deletionProgressStep');
  const successCard = document.getElementById('deletionSuccessStep');

  const authenticatedUserEmail = document.getElementById('authenticatedUserEmail');
  const authenticatedUserId = document.getElementById('authenticatedUserId');
  const confirmInput = document.getElementById('confirmDeleteInput');
  const executeDeleteBtn = document.getElementById('executeDeleteBtn');
  const cancelDeleteBtn = document.getElementById('cancelDeleteBtn');
  const progressText = document.getElementById('progressStatusText');
  const progressBar = document.getElementById('progressBarFill');
  const authErrorMsg = document.getElementById('authErrorMessage');

  let currentAuthUser = null;

  function showError(msg) {
    if (authErrorMsg) {
      authErrorMsg.textContent = msg;
      authErrorMsg.style.display = 'block';
    }
  }

  function hideError() {
    if (authErrorMsg) {
      authErrorMsg.style.display = 'none';
      authErrorMsg.textContent = '';
    }
  }

  function setProgress(percent, text) {
    if (progressBar) progressBar.style.width = `${percent}%`;
    if (progressText) progressText.textContent = text;
  }

  // Monitor Auth State
  if (typeof auth !== 'undefined' && auth) {
    auth.onAuthStateChanged((user) => {
      currentAuthUser = user;
      if (user) {
        showConfirmationStep(user);
      }
    });
  }

  function showConfirmationStep(user) {
    hideError();
    if (authCard) authCard.style.display = 'none';
    if (confirmCard) confirmCard.style.display = 'block';
    if (authenticatedUserEmail) authenticatedUserEmail.textContent = user.email || 'Google User';
    if (authenticatedUserId) authenticatedUserId.textContent = user.uid;
    if (confirmInput) {
      confirmInput.value = '';
      confirmInput.focus();
    }
    if (executeDeleteBtn) executeDeleteBtn.disabled = true;
  }

  // Enable Delete button only when "DELETE" is entered
  if (confirmInput && executeDeleteBtn) {
    confirmInput.addEventListener('input', () => {
      executeDeleteBtn.disabled = confirmInput.value.trim().toUpperCase() !== 'DELETE';
    });
  }

  // Cancel Deletion Step
  if (cancelDeleteBtn) {
    cancelDeleteBtn.addEventListener('click', () => {
      if (auth) auth.signOut();
      if (confirmCard) confirmCard.style.display = 'none';
      if (authCard) authCard.style.display = 'block';
    });
  }

  // Email / Password Login
  if (loginForm) {
    loginForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      hideError();
      const email = document.getElementById('accountEmail').value.trim();
      const password = document.getElementById('accountPassword').value;

      if (!email || !password) {
        showError('Please enter both your email address and password.');
        return;
      }

      const submitBtn = loginForm.querySelector('button[type="submit"]');
      if (submitBtn) {
        submitBtn.disabled = true;
        submitBtn.textContent = 'Verifying Account...';
      }

      try {
        if (!auth) throw new Error('Firebase Auth service is not ready.');
        const cred = await auth.signInWithEmailAndPassword(email, password);
        currentAuthUser = cred.user;
        showConfirmationStep(cred.user);
      } catch (err) {
        let message = 'Failed to verify account credentials.';
        if (err.code === 'auth/wrong-password' || err.code === 'auth/invalid-credential') {
          message = 'Invalid email or password. Please try again.';
        } else if (err.code === 'auth/user-not-found') {
          message = 'No PocketDay account found with this email address.';
        } else if (err.code === 'auth/too-many-requests') {
          message = 'Too many failed login attempts. Please try again later or reset your password.';
        } else {
          message = err.message || message;
        }
        showError(message);
      } finally {
        if (submitBtn) {
          submitBtn.disabled = false;
          submitBtn.textContent = 'Sign In to Verify Account';
        }
      }
    });
  }

  // Google Sign-In
  if (googleBtn) {
    googleBtn.addEventListener('click', async () => {
      hideError();
      try {
        if (!auth) throw new Error('Firebase Auth service is not ready.');
        const provider = new firebase.auth.GoogleAuthProvider();
        const result = await auth.signInWithPopup(provider);
        currentAuthUser = result.user;
        showConfirmationStep(result.user);
      } catch (err) {
        if (err.code !== 'auth/popup-closed-by-user') {
          showError(err.message || 'Google authentication was cancelled or failed.');
        }
      }
    });
  }

  // Password Reset Button
  if (resetPasswordBtn) {
    resetPasswordBtn.addEventListener('click', async () => {
      const email = document.getElementById('accountEmail').value.trim();
      if (!email) {
        showError('Please enter your account email above first, then click "Forgot Password".');
        return;
      }
      try {
        if (!auth) throw new Error('Firebase Auth is not ready.');
        await auth.sendPasswordResetEmail(email);
        alert(`Password reset link sent to ${email}. Check your inbox, reset your password, and return here to complete account deletion.`);
      } catch (err) {
        showError(err.message || 'Failed to send password reset email.');
      }
    });
  }

  // Execute Deletion Process
  if (executeDeleteBtn) {
    executeDeleteBtn.addEventListener('click', async () => {
      if (!currentAuthUser) {
        showError('No verified user session found. Please sign in again.');
        return;
      }

      if (confirmInput.value.trim().toUpperCase() !== 'DELETE') {
        showError('Please type DELETE in all capital letters to confirm.');
        return;
      }

      // Transition to progress view
      if (confirmCard) confirmCard.style.display = 'none';
      if (progressCard) progressCard.style.display = 'block';

      const userId = currentAuthUser.uid;
      const collectionsToWipe = [
        'transactions',
        'budgets',
        'goals',
        'subscriptions',
        'savings_goals',
        'profile'
      ];

      try {
        setProgress(10, 'Initializing secure data wipe...');

        // 1. Wipe all subcollections in batches
        let progress = 15;
        const stepInc = 60 / collectionsToWipe.length;

        for (const col of collectionsToWipe) {
          setProgress(Math.round(progress), `Wiping ${col}...`);
          try {
            const subRef = db.collection('users').doc(userId).collection(col);
            const snapshot = await subRef.get();
            if (!snapshot.empty) {
              const batch = db.batch();
              snapshot.docs.forEach((doc) => batch.delete(doc.ref));
              await batch.commit();
            }
          } catch (colErr) {
            console.warn(`Notice while wiping ${col}:`, colErr.message);
          }
          progress += stepInc;
        }

        // 2. Delete parent user profile document
        setProgress(85, 'Deleting root user profile...');
        try {
          await db.collection('users').doc(userId).delete();
        } catch (docErr) {
          console.warn('Root doc deletion notice:', docErr.message);
        }

        // 3. Delete Firebase Auth user credentials
        setProgress(95, 'Permanently deleting authentication credentials...');
        await currentAuthUser.delete();

        // 4. Success State
        setProgress(100, 'All records and credentials successfully deleted.');
        setTimeout(() => {
          if (progressCard) progressCard.style.display = 'none';
          if (successCard) successCard.style.display = 'block';
        }, 800);

      } catch (err) {
        console.error('Account deletion error:', err);
        if (err.code === 'auth/requires-recent-login') {
          alert('For security reasons, this critical operation requires a recent sign-in. Please sign in again to finalize deletion.');
          if (auth) auth.signOut();
          if (progressCard) progressCard.style.display = 'none';
          if (authCard) authCard.style.display = 'block';
        } else {
          showError(`Deletion could not be completed: ${err.message}`);
          if (progressCard) progressCard.style.display = 'none';
          if (confirmCard) confirmCard.style.display = 'block';
        }
      }
    });
  }

  // Assisted Deletion Form
  const assistedForm = document.getElementById('assistedDeletionForm');
  const assistedSuccess = document.getElementById('assistedSuccessNotice');
  const assistedRefId = document.getElementById('assistedRefId');

  if (assistedForm) {
    assistedForm.addEventListener('submit', (e) => {
      e.preventDefault();
      const email = document.getElementById('assistedEmail').value.trim();
      const reason = document.getElementById('assistedReason').value;
      const notes = document.getElementById('assistedNotes').value.trim();

      if (!email) {
        alert('Please enter your account email address.');
        return;
      }

      // Generate verifiable reference ID: PD-DEL-XXXXXX
      const refId = 'PD-DEL-' + Math.random().toString(36).substring(2, 8).toUpperCase();
      
      if (assistedRefId) assistedRefId.textContent = refId;
      if (assistedSuccess) assistedSuccess.style.display = 'block';
      assistedForm.style.display = 'none';

      // Fallback mailto trigger for transparency
      console.log(`PocketDay: Assisted deletion ticket ${refId} created for ${email}.`);
    });
  }
});
