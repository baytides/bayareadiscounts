/**
 * Bay Navigator - Shared Utilities
 *
 * Common utility functions used across multiple JavaScript modules.
 * This consolidates duplicate code and provides a single source of truth.
 */

(function () {
  'use strict';

  // ============================================================
  // STRING UTILITIES
  // ============================================================

  /**
   * Escape HTML entities to prevent XSS
   * @param {string} text - The text to escape
   * @returns {string} - HTML-safe text
   */
  function escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // ============================================================
  // DOM UTILITIES
  // ============================================================

  /**
   * Query selector shorthand
   * @param {string} selector - CSS selector
   * @param {Element} [parent=document] - Parent element
   * @returns {Element|null}
   */
  function qs(selector, parent = document) {
    return parent.querySelector(selector);
  }

  /**
   * Query selector all shorthand (returns array)
   * @param {string} selector - CSS selector
   * @param {Element} [parent=document] - Parent element
   * @returns {Element[]}
   */
  function qsa(selector, parent = document) {
    return Array.from(parent.querySelectorAll(selector));
  }

  /**
   * Show an element by removing display:none
   * @param {Element} el - Element to show
   * @param {string} [display=''] - Display value (empty string removes inline style)
   */
  function show(el, display = '') {
    if (el) el.style.display = display;
  }

  /**
   * Hide an element with display:none
   * @param {Element} el - Element to hide
   */
  function hide(el) {
    if (el) el.style.display = 'none';
  }

  /**
   * Toggle element visibility
   * @param {Element} el - Element to toggle
   * @param {boolean} visible - Whether to show the element
   * @param {string} [display=''] - Display value when visible
   */
  function toggle(el, visible, display = '') {
    if (el) el.style.display = visible ? display : 'none';
  }

  // ============================================================
  // STORAGE UTILITIES
  // ============================================================

  /**
   * Safe localStorage get with JSON parsing
   * @param {string} key - Storage key
   * @param {*} [fallback=null] - Fallback value if not found or error
   * @returns {*} - Parsed value or fallback
   */
  function storageGet(key, fallback = null) {
    try {
      const raw = localStorage.getItem(key);
      return raw ? JSON.parse(raw) : fallback;
    } catch (e) {
      console.warn(`Storage get error for "${key}":`, e);
      return fallback;
    }
  }

  /**
   * Safe localStorage set with JSON stringification
   * @param {string} key - Storage key
   * @param {*} value - Value to store (will be JSON stringified)
   * @returns {boolean} - Whether the operation succeeded
   */
  function storageSet(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value));
      return true;
    } catch (e) {
      console.warn(`Storage set error for "${key}" (private browsing?):`, e);
      return false;
    }
  }

  /**
   * Safe localStorage remove
   * @param {string} key - Storage key
   * @returns {boolean} - Whether the operation succeeded
   */
  function storageRemove(key) {
    try {
      localStorage.removeItem(key);
      return true;
    } catch (e) {
      console.warn(`Storage remove error for "${key}":`, e);
      return false;
    }
  }

  // ============================================================
  // ACCESSIBILITY UTILITIES
  // ============================================================

  // Shared announcement element
  let announcerEl = null;

  /**
   * Announce a message to screen readers
   * @param {string} message - Message to announce
   * @param {string} [priority='polite'] - 'polite' or 'assertive'
   */
  function announce(message, priority = 'polite') {
    if (!announcerEl) {
      announcerEl = document.createElement('div');
      announcerEl.setAttribute('role', 'status');
      announcerEl.setAttribute('aria-live', 'polite');
      announcerEl.setAttribute('aria-atomic', 'true');
      announcerEl.className = 'sr-only';
      document.body.appendChild(announcerEl);
    }

    announcerEl.setAttribute('aria-live', priority);

    // Clear and set to trigger announcement
    announcerEl.textContent = '';
    requestAnimationFrame(() => {
      announcerEl.textContent = message;
    });
  }

  // ============================================================
  // NOTIFICATION UTILITIES
  // ============================================================

  /**
   * Show a toast notification
   * @param {string} message - Message to display
   * @param {Object} [options={}] - Options
   * @param {number} [options.duration=3000] - Duration in ms
   * @param {string} [options.type='info'] - Type: 'info', 'success', 'error', 'warning'
   */
  function showToast(message, options = {}) {
    const { duration = 3000, type = 'info' } = options;

    // Remove existing toast
    const existing = document.querySelector('.app-toast');
    if (existing) existing.remove();

    // Create toast element
    const toast = document.createElement('div');
    toast.className = `app-toast app-toast-${type}`;
    toast.setAttribute('role', 'alert');
    toast.setAttribute('aria-live', 'polite');
    toast.textContent = message;

    // Apply styles
    Object.assign(toast.style, {
      position: 'fixed',
      bottom: '20px',
      left: '50%',
      transform: 'translateX(-50%)',
      padding: '12px 24px',
      borderRadius: '8px',
      fontSize: '14px',
      fontWeight: '500',
      zIndex: '10001',
      boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
      opacity: '0',
      transition: 'opacity 0.3s ease',
    });

    // Type-specific colors
    const colors = {
      info: { bg: '#1f2937', color: '#f3f4f6' },
      success: { bg: '#22c55e', color: '#ffffff' },
      error: { bg: '#ef4444', color: '#ffffff' },
      warning: { bg: '#f59e0b', color: '#1f2937' },
    };
    const { bg, color } = colors[type] || colors.info;
    toast.style.background = bg;
    toast.style.color = color;

    document.body.appendChild(toast);

    // Animate in
    requestAnimationFrame(() => {
      toast.style.opacity = '1';
    });

    // Auto-remove
    setTimeout(() => {
      toast.style.opacity = '0';
      setTimeout(() => toast.remove(), 300);
    }, duration);

    // Also announce for screen readers
    announce(message);
  }

  // ============================================================
  // URL UTILITIES
  // ============================================================

  /**
   * Add UTM parameters to external URLs for referral tracking
   * @param {string} url - The URL to add UTM parameters to
   * @param {Object} [options={}] - Options
   * @param {string} [options.source='baynavigator'] - UTM source
   * @param {string} [options.medium='referral'] - UTM medium
   * @param {string} [options.campaign] - UTM campaign (defaults to current page)
   * @returns {string} - URL with UTM parameters
   */
  function addUtmParams(url, options = {}) {
    if (!url) return url;

    try {
      const urlObj = new URL(url);

      // Skip if already has UTM params or is same origin
      if (urlObj.searchParams.has('utm_source') || urlObj.origin === window.location.origin) {
        return url;
      }

      // Skip certain domains that don't benefit from UTM tracking
      const skipDomains = ['google.com', 'maps.google.com', 'tel:', 'mailto:'];
      if (skipDomains.some((d) => url.includes(d))) {
        return url;
      }

      const {
        source = 'baynavigator',
        medium = 'referral',
        campaign = getCurrentPageName(),
      } = options;

      urlObj.searchParams.set('utm_source', source);
      urlObj.searchParams.set('utm_medium', medium);
      if (campaign) {
        urlObj.searchParams.set('utm_campaign', campaign);
      }

      return urlObj.toString();
    } catch (e) {
      // Invalid URL, return as-is
      return url;
    }
  }

  /**
   * Get current page name for UTM campaign parameter
   * @returns {string} - Page name
   */
  function getCurrentPageName() {
    const path = window.location.pathname.replace(/^\/|\/$/g, '');
    if (!path || path === '') return 'home';
    return path.split('/')[0] || 'home';
  }

  /**
   * Initialize UTM tracking on all external links
   * Call this on page load to automatically add UTM params to external links
   */
  function initUtmTracking() {
    // Process existing links
    document.querySelectorAll('a[href^="http"]').forEach((link) => {
      const href = link.getAttribute('href');
      if (href && !href.startsWith(window.location.origin)) {
        link.setAttribute('href', addUtmParams(href));
      }
    });

    // Observer for dynamically added links
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        mutation.addedNodes.forEach((node) => {
          if (node.nodeType === Node.ELEMENT_NODE) {
            // Check if the node itself is a link
            if (
              node.tagName === 'A' &&
              node.href &&
              !node.href.startsWith(window.location.origin)
            ) {
              node.setAttribute('href', addUtmParams(node.href));
            }
            // Check for links within the added node
            node.querySelectorAll?.('a[href^="http"]').forEach((link) => {
              const href = link.getAttribute('href');
              if (href && !href.startsWith(window.location.origin)) {
                link.setAttribute('href', addUtmParams(href));
              }
            });
          }
        });
      });
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true,
    });
  }

  // Auto-initialize UTM tracking when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initUtmTracking);
  } else {
    initUtmTracking();
  }

  // ============================================================
  // EXPORT
  // ============================================================

  window.AppUtils = {
    // String utilities
    escapeHtml,

    // DOM utilities
    qs,
    qsa,
    show,
    hide,
    toggle,

    // Storage utilities
    storageGet,
    storageSet,
    storageRemove,

    // Accessibility utilities
    announce,

    // Notification utilities
    showToast,

    // URL utilities
    addUtmParams,
    getCurrentPageName,
    initUtmTracking,
  };

  // Dispatch event when ready
  document.dispatchEvent(new CustomEvent('utilsReady'));
})();
