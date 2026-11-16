/**
 * PocketDay — Main Interactive Script
 * Navigation, Mobile Drawer, FAQ Accordion, UI Interactions
 */

document.addEventListener('DOMContentLoaded', () => {
  // Mobile Navigation Drawer Toggle
  const menuToggle = document.getElementById('mobileMenuToggle');
  const closeDrawer = document.getElementById('closeDrawer');
  const navDrawer = document.getElementById('mobileNavDrawer');
  const overlay = document.getElementById('mobileOverlay');

  function openMenu() {
    if (navDrawer && overlay) {
      navDrawer.classList.add('open');
      overlay.classList.add('active');
      document.body.style.overflow = 'hidden';
    }
  }

  function closeMenu() {
    if (navDrawer && overlay) {
      navDrawer.classList.remove('open');
      overlay.classList.remove('active');
      document.body.style.overflow = '';
    }
  }

  if (menuToggle) menuToggle.addEventListener('click', openMenu);
  if (closeDrawer) closeDrawer.addEventListener('click', closeMenu);
  if (overlay) overlay.addEventListener('click', closeMenu);

  // Close mobile drawer on escape key
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeMenu();
  });

  // Sticky Header elevation on scroll
  const header = document.querySelector('.site-header');
  window.addEventListener('scroll', () => {
    if (header) {
      if (window.scrollY > 20) {
        header.style.boxShadow = '0 10px 30px -10px rgba(0, 0, 0, 0.7)';
        header.style.borderBottomColor = 'rgba(255, 255, 255, 0.12)';
      } else {
        header.style.boxShadow = 'none';
        header.style.borderBottomColor = 'rgba(255, 255, 255, 0.08)';
      }
    }
  });

  // FAQ Accordion functionality
  const faqItems = document.querySelectorAll('.faq-item');
  faqItems.forEach((item) => {
    const questionBtn = item.querySelector('.faq-question');
    if (questionBtn) {
      questionBtn.addEventListener('click', () => {
        const isActive = item.classList.contains('active');
        // Close all other items
        faqItems.forEach((other) => other.classList.remove('active'));
        // Toggle current
        if (!isActive) {
          item.classList.add('active');
        }
      });
    }
  });

  // Mark active navigation link
  const currentPath = window.location.pathname.replace(/\/$/, '') || '/';
  const navLinks = document.querySelectorAll('.nav-link, .mobile-nav-links a');
  navLinks.forEach((link) => {
    const href = link.getAttribute('href');
    if (href) {
      const normalizedHref = href.replace(/\/$/, '') || '/';
      if (normalizedHref === currentPath) {
        link.classList.add('active');
      }
    }
  });
});
