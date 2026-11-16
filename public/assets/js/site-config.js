/**
 * PocketDay — Centralized Website & Brand Configuration
 * Destination: welkince.dev@gmail.com
 */

const SITE_CONFIG = {
  productName: "PocketDay",
  tagline: "Your money. Your rhythm.",
  publisherBrand: "PocketDay",
  
  // Dedicated verified support email
  supportEmail: "welkince.dev@gmail.com",
  
  // Public web URLs
  urls: {
    home: "/",
    privacyPolicy: "/privacy-policy",
    deleteAccount: "/delete-account",
    contact: "/contact",
    terms: "/terms",
  },

  supportNotice: "Direct support is managed through our web contact form and within the PocketDay mobile application (Profile > Support).",
  
  // Active Firebase Project ID
  firebaseProjectId: "pocketday-1679a"
};

if (typeof window !== 'undefined') {
  window.SITE_CONFIG = SITE_CONFIG;
}
