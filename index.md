---
layout: default
actions: true
---

{% include welcome.html %}

<!-- Hero Section -->
<section class="hero-section">
  <div class="hero-content">
    <h1 class="hero-title">Find programs and services in the Bay Area</h1>
    <p class="hero-subtitle">Discover free and low-cost resources for food, housing, healthcare, utilities, and more.</p>
    <div class="hero-search">
      <svg class="hero-search-icon" xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <circle cx="11" cy="11" r="8"></circle>
        <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
      </svg>
      <input type="search" id="hero-search" class="hero-search-input" placeholder="Search for food assistance, utilities, healthcare..." aria-label="Search programs">
    </div>
    <p class="hero-stats">
      <span class="stat-number">{{ site.data.programs | map: 'size' | sum }}+</span> programs available
    </p>
  </div>
</section>

<!-- Quick Links Section -->
<section class="quick-links-section">
  <h2 class="section-title">Popular Resources</h2>
  <div class="quick-links-grid">
    <a href="/eligibility/public-assistance.html" class="quick-link-card">
      <div class="quick-link-icon" style="background: #e8f5e9; color: #2e7d32;">
        <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"></path>
          <line x1="3" y1="6" x2="21" y2="6"></line>
          <path d="M16 10a4 4 0 0 1-8 0"></path>
        </svg>
      </div>
      <div class="quick-link-content">
        <h3>Food Assistance</h3>
        <p>CalFresh, food banks, and meal programs for individuals and families</p>
      </div>
      <span class="quick-link-arrow" aria-hidden="true">→</span>
    </a>

    <a href="/eligibility/utility-programs.html" class="quick-link-card">
      <div class="quick-link-icon" style="background: #fff3e0; color: #e65100;">
        <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon>
        </svg>
      </div>
      <div class="quick-link-content">
        <h3>Utility Assistance</h3>
        <p>Help with electricity, gas, water, and phone bills</p>
      </div>
      <span class="quick-link-arrow" aria-hidden="true">→</span>
    </a>

    <a href="/eligibility/" class="quick-link-card">
      <div class="quick-link-icon" style="background: #e0f7fa; color: #00838f;">
        <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
          <polyline points="14 2 14 8 20 8"></polyline>
          <line x1="16" y1="13" x2="8" y2="13"></line>
          <line x1="16" y1="17" x2="8" y2="17"></line>
        </svg>
      </div>
      <div class="quick-link-content">
        <h3>Eligibility Guides</h3>
        <p>Find out what programs you qualify for based on your situation</p>
      </div>
      <span class="quick-link-arrow" aria-hidden="true">→</span>
    </a>
  </div>
</section>

<!-- Category Filters Section -->
<section class="categories-section">
  <h2 class="section-title">Browse by Category</h2>
  <div class="category-filters" role="group" aria-label="Filter by category">
    <button type="button" class="category-btn active" data-category="all">
      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="7" height="7"></rect><rect x="14" y="3" width="7" height="7"></rect><rect x="14" y="14" width="7" height="7"></rect><rect x="3" y="14" width="7" height="7"></rect></svg>
      All
    </button>
    <button type="button" class="category-btn" data-category="Food">
      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"></path><line x1="3" y1="6" x2="21" y2="6"></line><path d="M16 10a4 4 0 0 1-8 0"></path></svg>
      Food
    </button>
    <button type="button" class="category-btn" data-category="Health">
      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19.5 12.572l-7.5 7.428-7.5-7.428a5 5 0 1 1 7.5-6.566 5 5 0 1 1 7.5 6.566z"></path></svg>
      Health
    </button>
    <button type="button" class="category-btn" data-category="Housing">
      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"></path><polyline points="9 22 9 12 15 12 15 22"></polyline></svg>
      Housing
    </button>
    <button type="button" class="category-btn" data-category="Utilities">
      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon></svg>
      Utilities
    </button>
    <button type="button" class="category-btn" data-category="Public Transit">
      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="4" width="18" height="12" rx="2"></rect><path d="M8 20h8"></path><path d="M12 16v4"></path></svg>
      Transit
    </button>
    <button type="button" class="category-btn" data-category="Education">
      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 10v6M2 10l10-5 10 5-10 5z"></path><path d="M6 12v5c3 3 9 3 12 0v-5"></path></svg>
      Education
    </button>
    <button type="button" class="category-btn" data-category="Employment">
      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"></rect><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"></path></svg>
      Jobs
    </button>
  </div>
</section>

<!-- Programs Search Bar (sticky) -->
<div class="programs-header">
  <div class="programs-search-bar">
    <input type="search" id="program-search" class="programs-search-input" placeholder="Search programs..." aria-label="Search programs">
    <button type="button" class="programs-filter-btn" data-open-onboarding aria-label="Update your preferences">
      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <line x1="4" y1="21" x2="4" y2="14"></line>
        <line x1="4" y1="10" x2="4" y2="3"></line>
        <line x1="12" y1="21" x2="12" y2="12"></line>
        <line x1="12" y1="8" x2="12" y2="3"></line>
        <line x1="20" y1="21" x2="20" y2="16"></line>
        <line x1="20" y1="12" x2="20" y2="3"></line>
        <line x1="1" y1="14" x2="7" y2="14"></line>
        <line x1="9" y1="8" x2="15" y2="8"></line>
        <line x1="17" y1="16" x2="23" y2="16"></line>
      </svg>
      <span>Filters</span>
    </button>
  </div>
  <div class="programs-active-filters" id="active-filters"></div>
</div>

<!-- Programs Grid -->
<div id="programs-list" class="programs-container" role="region" aria-live="polite" aria-label="Programs">
{% assign all_programs = "" | split: "" %}
{% for category in site.data.programs %}
  {% for program in category[1] %}
    {% assign all_programs = all_programs | push: program %}
  {% endfor %}
{% endfor %}
{% assign sorted_programs = all_programs | sort: "name" %}
{% for program in sorted_programs %}
  {% include program-card.html program=program %}
{% endfor %}
</div>

{% include back-to-top.html %}

<style>
/* ============================================
   HERO SECTION
   ============================================ */
.hero-section {
  background: linear-gradient(135deg, #00838f 0%, #006064 100%);
  color: white;
  padding: 3rem 1.5rem;
  margin: -1rem -1rem 0;
  text-align: center;
}

.hero-content {
  max-width: 700px;
  margin: 0 auto;
}

.hero-title {
  font-size: clamp(1.5rem, 4vw, 2.25rem);
  font-weight: 700;
  margin: 0 0 0.75rem;
  line-height: 1.2;
}

.hero-subtitle {
  font-size: clamp(0.95rem, 2vw, 1.125rem);
  opacity: 0.9;
  margin: 0 0 1.5rem;
  line-height: 1.5;
}

.hero-search {
  position: relative;
  max-width: 500px;
  margin: 0 auto 1rem;
}

.hero-search-icon {
  position: absolute;
  left: 1rem;
  top: 50%;
  transform: translateY(-50%);
  color: #6b7280;
  pointer-events: none;
}

.hero-search-input {
  width: 100%;
  padding: 1rem 1rem 1rem 3rem;
  font-size: 1rem;
  border: none;
  border-radius: 12px;
  background: white;
  color: #1f2937;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.15);
}

.hero-search-input::placeholder {
  color: #9ca3af;
}

.hero-search-input:focus {
  outline: 3px solid rgba(255, 255, 255, 0.5);
  outline-offset: 2px;
}

.hero-stats {
  font-size: 0.875rem;
  opacity: 0.85;
  margin: 0;
}

.stat-number {
  font-weight: 700;
  font-size: 1.125rem;
}

/* ============================================
   QUICK LINKS SECTION
   ============================================ */
.quick-links-section {
  padding: 2rem 0;
}

.section-title {
  font-size: 1.25rem;
  font-weight: 600;
  color: #1f2937;
  margin: 0 0 1rem;
  text-align: center;
}

.quick-links-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1rem;
}

.quick-link-card {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.25rem;
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 12px;
  text-decoration: none;
  color: inherit;
  transition: all 0.2s ease;
}

.quick-link-card:hover {
  border-color: #00838f;
  box-shadow: 0 4px 12px rgba(0, 131, 143, 0.15);
  transform: translateY(-2px);
}

.quick-link-icon {
  flex-shrink: 0;
  width: 56px;
  height: 56px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
}

.quick-link-content {
  flex: 1;
  min-width: 0;
}

.quick-link-content h3 {
  font-size: 1rem;
  font-weight: 600;
  color: #1f2937;
  margin: 0 0 0.25rem;
}

.quick-link-content p {
  font-size: 0.875rem;
  color: #6b7280;
  margin: 0;
  line-height: 1.4;
}

.quick-link-arrow {
  flex-shrink: 0;
  font-size: 1.25rem;
  color: #00838f;
  transition: transform 0.2s;
}

.quick-link-card:hover .quick-link-arrow {
  transform: translateX(4px);
}

/* ============================================
   CATEGORY FILTERS
   ============================================ */
.categories-section {
  padding: 1rem 0 1.5rem;
  border-bottom: 1px solid #e5e7eb;
  margin-bottom: 1rem;
}

.category-filters {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  justify-content: center;
}

.category-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.5rem 1rem;
  font-size: 0.875rem;
  font-weight: 500;
  color: #4b5563;
  background: #f3f4f6;
  border: 1px solid transparent;
  border-radius: 9999px;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.category-btn:hover {
  background: #e5e7eb;
  color: #1f2937;
}

.category-btn:focus-visible {
  outline: 2px solid #00838f;
  outline-offset: 2px;
}

.category-btn.active {
  background: #00838f;
  color: white;
  border-color: #00838f;
}

.category-btn svg {
  flex-shrink: 0;
}

/* ============================================
   PROGRAMS HEADER (Sticky Search)
   ============================================ */
.programs-header {
  position: sticky;
  top: 0;
  z-index: 100;
  background: var(--bg-primary, #ffffff);
  padding: 1rem 0;
  margin-bottom: 1rem;
  border-bottom: 1px solid var(--border-color, #e5e7eb);
}

.programs-search-bar {
  display: flex;
  gap: 0.75rem;
  max-width: 600px;
  margin: 0 auto;
}

.programs-search-input {
  flex: 1;
  padding: 0.75rem 1rem;
  font-size: 1rem;
  border: 1px solid var(--border-color, #e5e7eb);
  border-radius: 10px;
  background: var(--bg-surface, #f9fafb);
  color: var(--text-primary, #111827);
  transition: all 0.2s;
}

.programs-search-input:focus {
  outline: none;
  border-color: #00838f;
  box-shadow: 0 0 0 3px rgba(0, 131, 143, 0.15);
  background: #ffffff;
}

.programs-search-input::placeholder {
  color: var(--text-secondary, #6b7280);
}

.programs-filter-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1rem;
  font-size: 0.9375rem;
  font-weight: 500;
  color: var(--text-primary, #374151);
  background: var(--bg-surface, #f9fafb);
  border: 1px solid var(--border-color, #e5e7eb);
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.programs-filter-btn:hover {
  background: #e5e7eb;
  border-color: #d1d5db;
}

.programs-filter-btn:focus-visible {
  outline: 2px solid #00838f;
  outline-offset: 2px;
}

.programs-active-filters {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
  justify-content: center;
  margin-top: 0.75rem;
}

.programs-active-filters:empty {
  display: none;
}

.active-filter-chip {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.375rem 0.75rem;
  font-size: 0.8125rem;
  font-weight: 500;
  color: #00695c;
  background: #e0f2f1;
  border-radius: 20px;
  border: none;
  cursor: pointer;
  transition: all 0.2s;
}

.active-filter-chip:hover {
  background: #b2dfdb;
}

.active-filter-chip svg {
  width: 14px;
  height: 14px;
}

/* ============================================
   DARK MODE
   ============================================ */
@media (prefers-color-scheme: dark) {
  .hero-section {
    background: linear-gradient(135deg, #004d40 0%, #00251a 100%);
  }

  .hero-search-input {
    background: #1f2937;
    color: #f3f4f6;
  }

  .hero-search-icon {
    color: #9ca3af;
  }

  .section-title {
    color: #f3f4f6;
  }

  .quick-link-card {
    background: #1f2937;
    border-color: #374151;
  }

  .quick-link-card:hover {
    border-color: #00838f;
  }

  .quick-link-content h3 {
    color: #f3f4f6;
  }

  .quick-link-content p {
    color: #9ca3af;
  }

  .categories-section {
    border-color: #374151;
  }

  .category-btn {
    background: #374151;
    color: #d1d5db;
  }

  .category-btn:hover {
    background: #4b5563;
    color: #f3f4f6;
  }

  .category-btn.active {
    background: #00838f;
    color: white;
  }

  .programs-header {
    background: #0d1117;
    border-color: #30363d;
  }

  .programs-search-input {
    background: #161b22;
    border-color: #30363d;
    color: #c9d1d9;
  }

  .programs-search-input:focus {
    border-color: #00838f;
    box-shadow: 0 0 0 3px rgba(0, 131, 143, 0.2);
    background: #161b22;
  }

  .programs-filter-btn {
    background: #161b22;
    border-color: #30363d;
    color: #c9d1d9;
  }

  .programs-filter-btn:hover {
    background: #21262d;
  }

  .active-filter-chip {
    background: #1e3a3a;
    color: #4fd1c5;
  }

  .active-filter-chip:hover {
    background: #264a4a;
  }
}

/* Manual dark mode toggle */
body[data-theme="dark"] .hero-section {
  background: linear-gradient(135deg, #004d40 0%, #00251a 100%);
}

body[data-theme="dark"] .hero-search-input {
  background: #1f2937;
  color: #f3f4f6;
}

body[data-theme="dark"] .section-title {
  color: #f3f4f6;
}

body[data-theme="dark"] .quick-link-card {
  background: #1f2937;
  border-color: #374151;
}

body[data-theme="dark"] .quick-link-content h3 {
  color: #f3f4f6;
}

body[data-theme="dark"] .quick-link-content p {
  color: #9ca3af;
}

body[data-theme="dark"] .categories-section {
  border-color: #374151;
}

body[data-theme="dark"] .category-btn {
  background: #374151;
  color: #d1d5db;
}

body[data-theme="dark"] .category-btn:hover {
  background: #4b5563;
}

body[data-theme="dark"] .category-btn.active {
  background: #00838f;
  color: white;
}

body[data-theme="dark"] .programs-header {
  background: #0d1117;
  border-color: #30363d;
}

body[data-theme="dark"] .programs-search-input {
  background: #161b22;
  border-color: #30363d;
  color: #c9d1d9;
}

body[data-theme="dark"] .programs-search-input:focus {
  border-color: #00838f;
}

body[data-theme="dark"] .programs-filter-btn {
  background: #161b22;
  border-color: #30363d;
  color: #c9d1d9;
}

body[data-theme="dark"] .active-filter-chip {
  background: #1e3a3a;
  color: #4fd1c5;
}

/* ============================================
   MOBILE RESPONSIVE
   ============================================ */
@media (max-width: 768px) {
  .hero-section {
    padding: 2rem 1rem;
    margin: -1rem -1rem 0;
  }

  .hero-search-input {
    padding: 0.875rem 0.875rem 0.875rem 2.75rem;
    font-size: 0.9375rem;
  }

  .hero-search-icon {
    left: 0.875rem;
    width: 18px;
    height: 18px;
  }

  .quick-links-section {
    padding: 1.5rem 0;
  }

  .quick-links-grid {
    grid-template-columns: 1fr;
  }

  .quick-link-card {
    padding: 1rem;
  }

  .quick-link-icon {
    width: 48px;
    height: 48px;
  }

  .quick-link-icon svg {
    width: 24px;
    height: 24px;
  }

  .category-filters {
    gap: 0.375rem;
    padding: 0 0.5rem;
  }

  .category-btn {
    padding: 0.375rem 0.75rem;
    font-size: 0.8125rem;
  }

  .category-btn svg {
    width: 16px;
    height: 16px;
  }

  .programs-header {
    padding: 0.75rem 0;
  }

  .programs-search-bar {
    padding: 0 0.5rem;
    gap: 0.5rem;
  }

  .programs-search-input {
    padding: 0.625rem 0.875rem;
    font-size: 0.9375rem;
  }

  .programs-filter-btn {
    padding: 0.625rem 0.75rem;
  }

  .programs-filter-btn span {
    display: none;
  }
}
</style>

<script>
document.addEventListener('DOMContentLoaded', function() {
  const heroSearch = document.getElementById('hero-search');
  const programSearch = document.getElementById('program-search');
  const programsList = document.getElementById('programs-list');
  const activeFiltersContainer = document.getElementById('active-filters');
  const categoryBtns = document.querySelectorAll('.category-btn');

  if (!programsList) return;

  const allCards = Array.from(programsList.querySelectorAll('.program-card'));
  let currentCategory = 'all';

  // Sync hero search with program search
  if (heroSearch) {
    heroSearch.addEventListener('input', function() {
      if (programSearch) programSearch.value = this.value;
      filterPrograms();
    });

    // Scroll to programs when user starts typing in hero search
    heroSearch.addEventListener('focus', function() {
      setTimeout(() => {
        document.querySelector('.programs-header')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
      }, 300);
    });
  }

  if (programSearch) {
    programSearch.addEventListener('input', function() {
      if (heroSearch) heroSearch.value = this.value;
      filterPrograms();
    });
  }

  // Category filter buttons
  categoryBtns.forEach(btn => {
    btn.addEventListener('click', function() {
      categoryBtns.forEach(b => b.classList.remove('active'));
      this.classList.add('active');
      currentCategory = this.dataset.category;
      filterPrograms();
    });
  });

  // Display active filters from preferences
  function displayActiveFilters() {
    if (!activeFiltersContainer) return;

    activeFiltersContainer.innerHTML = '';

    if (window.Preferences && window.Preferences.hasPreferences()) {
      const prefs = window.Preferences.get();

      if (prefs.groups && prefs.groups.length > 0) {
        prefs.groups.forEach(group => {
          const chip = document.createElement('button');
          chip.className = 'active-filter-chip';
          chip.innerHTML = `${formatGroupName(group)} <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>`;
          chip.addEventListener('click', () => removeFilter('group', group));
          activeFiltersContainer.appendChild(chip);
        });
      }

      if (prefs.county) {
        const chip = document.createElement('button');
        chip.className = 'active-filter-chip';
        chip.innerHTML = `${formatCountyName(prefs.county)} <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>`;
        chip.addEventListener('click', () => removeFilter('county', prefs.county));
        activeFiltersContainer.appendChild(chip);
      }
    }
  }

  function formatGroupName(id) {
    const names = {
      'income-eligible': 'Income-Eligible', 'seniors': 'Seniors', 'youth': 'Youth',
      'college-students': 'Students', 'veterans': 'Veterans', 'families': 'Families',
      'disability': 'Disability', 'lgbtq': 'LGBT+', 'first-responders': 'First Responders',
      'teachers': 'Teachers', 'unemployed': 'Job Seekers', 'immigrants': 'Immigrants',
      'unhoused': 'Unhoused', 'pregnant': 'Pregnant', 'caregivers': 'Caregivers',
      'foster-youth': 'Foster Youth', 'reentry': 'Reentry', 'nonprofits': 'Nonprofits',
      'everyone': 'Everyone'
    };
    return names[id] || id;
  }

  function formatCountyName(id) {
    const names = {
      'san-francisco': 'San Francisco', 'alameda': 'Alameda County',
      'contra-costa': 'Contra Costa County', 'san-mateo': 'San Mateo County',
      'santa-clara': 'Santa Clara County', 'marin': 'Marin County',
      'napa': 'Napa County', 'solano': 'Solano County', 'sonoma': 'Sonoma County'
    };
    return names[id] || id;
  }

  function removeFilter(type, value) {
    if (!window.Preferences) return;
    const prefs = window.Preferences.get();

    if (type === 'group') {
      prefs.groups = prefs.groups.filter(g => g !== value);
      window.Preferences.setGroups(prefs.groups);
    } else if (type === 'county') {
      window.Preferences.setCounty(null);
    }

    displayActiveFilters();
    filterPrograms();
  }

  function filterPrograms() {
    const query = (programSearch?.value || heroSearch?.value || '').toLowerCase().trim();
    const prefs = window.Preferences ? window.Preferences.get() : { groups: [], county: null };

    let visibleCount = 0;

    allCards.forEach(card => {
      const name = (card.dataset.programName || card.dataset.name || '').toLowerCase();
      const category = (card.dataset.category || '').toLowerCase();
      const area = (card.dataset.area || '').toLowerCase();
      const groups = (card.dataset.groups || '').toLowerCase().split(/[\s,]+/).map(g => g.trim());
      const description = (card.querySelector('.card-description')?.textContent || '').toLowerCase();

      // Category filter
      const matchesCategory = currentCategory === 'all' || category === currentCategory.toLowerCase();

      // Search query
      const matchesSearch = !query ||
        name.includes(query) ||
        category.includes(query) ||
        area.includes(query) ||
        description.includes(query);

      // Group filters
      const matchesGroups = !prefs.groups || prefs.groups.length === 0 ||
        prefs.groups.some(g => groups.includes(g)) ||
        groups.includes('everyone');

      // County filter
      const matchesCounty = !prefs.county ||
        area.includes(prefs.county.replace('-', ' ')) ||
        area.includes('statewide') ||
        area.includes('nationwide') ||
        area.includes('bay area');

      const visible = matchesCategory && matchesSearch && matchesGroups && matchesCounty;
      card.style.display = visible ? '' : 'none';

      if (visible) visibleCount++;
    });
  }

  // Listen for preference changes
  document.addEventListener('preferencesChanged', function() {
    displayActiveFilters();
    filterPrograms();
  });

  document.addEventListener('onboardingComplete', function() {
    displayActiveFilters();
    filterPrograms();
  });

  // Initial display
  displayActiveFilters();
  filterPrograms();
});
</script>
