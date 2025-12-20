/**
 * Azure AI Translator Client
 * Privacy-focused translation using Azure Functions backend
 */

// Uses shared translation helper + cache for reuse across web/mobile
class AzureTranslator {
  constructor(apiEndpoint) {
    // Use production Azure Function endpoint or local development
    this.apiEndpoint = apiEndpoint || window.DEFAULT_TRANSLATE_ENDPOINT || '';
    this.currentLang = 'en';
    this.originalContent = new Map();

    // Prefer shared cache; fall back to in-memory map
    if (window.sharedCache) {
      this.cache = window.sharedCache;
    } else {
      const { createCache } = window.sharedLibs || {};
      this.cache = createCache ? createCache({ storage: window.localStorage }) : new Map();
    }

    this.isConfigured = !this.apiEndpoint.includes('YOUR_FUNCTION_APP');
  }

  /**
   * Translate the entire page to target language
   */
  async translatePage(targetLang) {
    if (targetLang === 'en') {
      this.restorePage();
      return;
    }

    // Check if API is configured
    if (!this.isConfigured) {
      this.showError('Translation feature is not yet configured. Please check AZURE_TRANSLATOR_SETUP.md for setup instructions.');
      return;
    }

    try {
      // Show loading indicator
      this.showLoading(true);

      // Collect all text content to translate
      const textsToTranslate = this.collectPageText();

      if (textsToTranslate.length === 0) {
        console.warn('No text found to translate');
        this.showLoading(false);
        return;
      }

      // Use shared translation helper with caching
      const translations = await this.translateTexts(textsToTranslate, targetLang);

      // Apply translations to page
      this.applyTranslations(translations);
      this.currentLang = targetLang;

      // Save preference
      localStorage.setItem('preferred_language', targetLang);

      this.showLoading(false);
    } catch (error) {
      console.error('Translation error:', error);
      this.showLoading(false);

      // Provide more helpful error message
      let errorMessage = 'Translation failed. ';
      if (error.message && error.message.includes('Failed to fetch')) {
        errorMessage += 'Unable to connect to translation service. Please check your internet connection or contact support.';
      } else if (error.message) {
        errorMessage += error.message;
      } else {
        errorMessage += 'Please try again or check AZURE_TRANSLATOR_SETUP.md for configuration.';
      }

      this.showError(errorMessage);
    }
  }

  /**
   * Collect all translatable text from the page
   */
  collectPageText() {
    const texts = [];
    const elements = [];

    // Select translatable elements - target specific text containers
    const selectors = [
      'h1:not([data-no-translate])',
      'h2:not([data-no-translate])',
      'h3:not([data-no-translate])',
      'p:not([data-no-translate]):not(.simple-language-summary)',
      '.program-name-text',
      '.program-benefit',
      '.program-area',
      '.program-category',
      '.eligibility-badge',
      '.program-badge',
      '.program-link',
      '.program-timeframe',
      '.search-field label',
      '.filter-group-label',
      '.filter-btn',
      '.reset-btn',
      '.sort-label',
      '.sort-select option'
    ];

    document.querySelectorAll(selectors.join(', ')).forEach(el => {
      // Skip if inside excluded containers
      if (el.closest('[data-no-translate]')) return;
      if (el.closest('.utility-bar')) return;
      if (el.closest('footer a')) return; // Skip footer links
      if (el.closest('.a11y-report-link')) return;

      // Avoid elements that contain nested markup to prevent layout breakage
      const hasElementChildren = Array.from(el.childNodes).some(node => node.nodeType === Node.ELEMENT_NODE);
      if (hasElementChildren) {
        // Allow specific safe elements with child spans (e.g., program name span inside h3)
        if (!el.classList.contains('program-name-text')) return;
      }
      
      const text = el.textContent.trim();
      if (text && text.length > 0) {
        // Store original content if not already stored
        if (!this.originalContent.has(el)) {
          this.originalContent.set(el, el.textContent);
        }
        texts.push(text);
        elements.push(el);
      }
    });

    this.elements = elements;
    return texts;
  }

  /**
   * Apply translations to page elements
   */
  applyTranslations(translations) {
    if (!this.elements || this.elements.length !== translations.length) {
      console.error('Mismatch between elements and translations');
      return;
    }

    this.elements.forEach((el, index) => {
      if (translations[index]) {
        // Only replace text content, preserving all HTML structure
        el.textContent = translations[index];
      }
    });
  }

  /**
   * Restore page to original English content
   */
  restorePage() {
    this.originalContent.forEach((original, el) => {
      el.textContent = original;
    });
    this.currentLang = 'en';
    localStorage.removeItem('preferred_language');
  }

  /**
   * Show/hide loading indicator
   */
  showLoading(show) {
    let loader = document.getElementById('translation-loader');

    if (!loader && show) {
      loader = document.createElement('div');
      loader.id = 'translation-loader';
      loader.style.cssText = `
        position: fixed;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        background: rgba(0, 0, 0, 0.8);
        color: white;
        padding: 20px 40px;
        border-radius: 8px;
        z-index: 10001;
        font-size: 16px;
      `;
      loader.textContent = 'Translating...';
      document.body.appendChild(loader);
    } else if (loader && !show) {
      loader.remove();
    }
  }

  /**
   * Show error message
   */
  showError(message) {
    const error = document.createElement('div');
    error.style.cssText = `
      position: fixed;
      top: 20px;
      right: 20px;
      background: #ef4444;
      color: white;
      padding: 16px 24px;
      border-radius: 8px;
      z-index: 10001;
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
    `;
    error.textContent = message;
    document.body.appendChild(error);

    setTimeout(() => error.remove(), 5000);
  }

  /**
   * Get supported languages
   */
  getSupportedLanguages() {
    return [
      { code: 'en', name: 'English', flag: '🇺🇸' },
      { code: 'es', name: 'Español', flag: '🇪🇸' },
      { code: 'zh-Hans', name: '简体中文', flag: '🇨🇳' },
      { code: 'tl', name: 'Tagalog', flag: '🇵🇭' },
      { code: 'vi', name: 'Tiếng Việt', flag: '🇻🇳' },
      { code: 'ko', name: '한국어', flag: '🇰🇷' },
      { code: 'ru', name: 'Русский', flag: '🇷🇺' },
      { code: 'ar', name: 'العربية', flag: '🇸🇦' },
      { code: 'fa', name: 'فارسی', flag: '🇮🇷' },
      { code: 'ja', name: '日本語', flag: '🇯🇵' },
      { code: 'fr', name: 'Français', flag: '🇫🇷' },
      { code: 'hi', name: 'हिन्दी', flag: '🇮🇳' }
    ];
  }

  async translateTexts(texts, targetLang) {
    const { translateTexts, DEFAULT_TRANSLATE_ENDPOINT } = window.sharedLibs || {};
    if (!translateTexts) {
      throw new Error('Translation library not loaded');
    }

    const endpoint = this.apiEndpoint || DEFAULT_TRANSLATE_ENDPOINT;
    const { translations } = await translateTexts({
      texts,
      targetLang,
      sourceLang: 'en',
      endpoint,
      cache: this.cache
    });

    return translations;
  }
}

// Initialize translator
window.azureTranslator = new AzureTranslator();

// Auto-restore preferred language on page load
document.addEventListener('DOMContentLoaded', () => {
  const preferredLang = localStorage.getItem('preferred_language');
  if (preferredLang && preferredLang !== 'en') {
    window.azureTranslator.translatePage(preferredLang);
  }
});
