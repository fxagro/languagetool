// DOM Elements
const demoTextarea = document.querySelector('.demo-textarea');
const demoCheckBtn = document.querySelector('.demo-btn:first-of-type');
const demoClearBtn = document.querySelector('.demo-btn:last-of-type');
const resultsContent = document.querySelector('.results-content');
const resultsCount = document.querySelector('.results-count');
const hamburger = document.querySelector('.hamburger');
const navMenu = document.querySelector('.nav-menu');
const languageDropdown = document.querySelector('.demo-language select');
const languagesGrid = document.querySelector('.languages-grid');

// Language flags mapping
const languageFlags = {
    'en-US': '🇺🇸', 'en-GB': '🇬🇧', 'de-DE': '🇩🇪', 'es-ES': '🇪🇸', 'fr-FR': '🇫🇷',
    'pt-PT': '🇵🇹', 'pt-BR': '🇧🇷', 'nl-NL': '🇳🇱', 'it-IT': '🇮🇹', 'ru-RU': '🇷🇺',
    'pl-PL': '🇵🇱', 'uk-UA': '🇺🇦', 'ca-ES': '🇨🇦', 'cs-CZ': '🇨🇿', 'da-DK': '🇩🇰',
    'el-GR': '🇬🇷', 'fi-FI': '🇫🇮', 'hu-HU': '🇭🇺', 'ja-JP': '🇯🇵', 'ko-KR': '🇰🇷',
    'nb-NO': '🇳🇴', 'nn-NO': '🇳🇴', 'sl-SI': '🇸🇮', 'sv-SE': '🇸🇪', 'tr-TR': '🇹🇷',
    'zh-CN': '🇨🇳', 'zh-TW': '🇹🇼', 'ar-SA': '🇸🇦', 'hi-IN': '🇮🇳', 'id-ID': '🇮🇩',
    'vi-VN': '🇻🇳', 'th-TH': '🇹🇭', 'bg-BG': '🇧🇬', 'ro-RO': '🇷🇴', 'sk-SK': '🇸🇰'
};

// Sample text for demo
const sampleTexts = {
    'en-US': `The quick brown fox jumps over the lazy dog. Teh cat sat on the mat. This sentance has some errors. I went to the store yesterday and bought some appls.`,
    'en-GB': `The colour of the sky is blue. I travelled to the centre of the city. Teh organisation has many members.`,
    'de-DE': `Das ist ein Beispieltext mit einige Fehlern. Teh Katze saß auf der Matte. Diese Satz hat Grammatikfehler.`,
    'es-ES': `El rápido zorro marrón salta sobre el perro perezoso. Teh gato se sentó en la alfombra. Este oración tiene errores.`,
    'fr-FR': `Le renard brun rapide saute par-dessus le chien paresseux. Teh chat s'est assis sur le tapis. Cette phrase a des erreurs.`
};

// Function to load all languages from LanguageTool API
async function loadLanguages() {
    try {
        const response = await fetch('http://vmi3028068.contaboserver.net/v2/languages');
        if (!response.ok) throw new Error('Failed to fetch languages');
        
        const languages = await response.json();
        
        // Update language selector in demo
        updateLanguageSelector(languages);
        
        // Update languages grid in languages section
        updateLanguagesGrid(languages);
        
        console.log('✅ Languages loaded:', languages.length);
    } catch (err) {
        console.error('❌ Error loading languages:', err);
        // Fallback to default languages if API fails
        loadDefaultLanguages();
    }
}

// Update language selector in demo section
function updateLanguageSelector(languages) {
    if (!languageDropdown) return;
    
    languageDropdown.innerHTML = '';
    
    languages.forEach(lang => {
        const option = document.createElement('option');
        option.value = lang.longCode;
        option.textContent = `${lang.name} (${lang.longCode})`;
        languageDropdown.appendChild(option);
    });
}

// Update languages grid in languages section
function updateLanguagesGrid(languages) {
    if (!languagesGrid) return;
    
    languagesGrid.innerHTML = '';
    
    languages.forEach(lang => {
        const languageItem = document.createElement('div');
        languageItem.className = 'language-item';
        
        const flag = languageFlags[lang.longCode] || '🌍';
        const languageName = lang.name;
        
        languageItem.innerHTML = `
            <div class="language-flag">${flag}</div>
            <span>${languageName}</span>
        `;
        
        languagesGrid.appendChild(languageItem);
    });
}

// Fallback to default languages if API fails
function loadDefaultLanguages() {
    const defaultLanguages = [
        { longCode: 'en-US', name: 'English (US)' },
        { longCode: 'en-GB', name: 'English (UK)' },
        { longCode: 'de-DE', name: 'German' },
        { longCode: 'es-ES', name: 'Spanish' },
        { longCode: 'fr-FR', name: 'French' },
        { longCode: 'pt-PT', name: 'Portuguese' },
        { longCode: 'pt-BR', name: 'Portuguese (Brazil)' },
        { longCode: 'nl-NL', name: 'Dutch' },
        { longCode: 'it-IT', name: 'Italian' },
        { longCode: 'ru-RU', name: 'Russian' },
        { longCode: 'pl-PL', name: 'Polish' },
        { longCode: 'uk-UA', name: 'Ukrainian' },
        { longCode: 'ca-ES', name: 'Catalan' },
        { longCode: 'cs-CZ', name: 'Czech' },
        { longCode: 'da-DK', name: 'Danish' },
        { longCode: 'el-GR', name: 'Greek' },
        { longCode: 'fi-FI', name: 'Finnish' },
        { longCode: 'hu-HU', name: 'Hungarian' },
        { longCode: 'ja-JP', name: 'Japanese' },
        { longCode: 'ko-KR', name: 'Korean' },
        { longCode: 'nb-NO', name: 'Norwegian (Bokmål)' },
        { longCode: 'nn-NO', name: 'Norwegian (Nynorsk)' },
        { longCode: 'sl-SI', name: 'Slovenian' },
        { longCode: 'sv-SE', name: 'Swedish' },
        { longCode: 'tr-TR', name: 'Turkish' },
        { longCode: 'zh-CN', name: 'Chinese (Simplified)' },
        { longCode: 'zh-TW', name: 'Chinese (Traditional)' }
    ];
    
    updateLanguageSelector(defaultLanguages);
    updateLanguagesGrid(defaultLanguages);
}

// Initialize
document.addEventListener('DOMContentLoaded', function() {
    setupEventListeners();
    
    // Set up optional features with null checks
    if (typeof IntersectionObserver !== 'undefined') {
        setupIntersectionObserver();
    }
    setupSmoothScrolling();
    
    // Load all languages from LanguageTool API
    loadLanguages();
});

// Event Listeners
function setupEventListeners() {
    // Demo functionality
    if (demoCheckBtn) demoCheckBtn.addEventListener('click', checkText);
    if (demoClearBtn) demoClearBtn.addEventListener('click', clearText);

    // Mobile menu
    if (hamburger) hamburger.addEventListener('click', toggleMobileMenu);

    // Language selector
    const languageSelect = document.querySelector('.demo-language select');
    if (languageSelect) languageSelect.addEventListener('change', loadSampleText);

    // Textarea auto-resize
    if (demoTextarea) demoTextarea.addEventListener('input', autoResizeTextarea);
}

// Intersection Observer for animations
function setupIntersectionObserver() {
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('fade-in-up');
            }
        });
    }, observerOptions);

    // Observe elements for animation
    document.querySelectorAll('.feature-card, .language-item, .testimonial-card').forEach(card => {
        observer.observe(card);
    });
}

// Smooth scrolling
function setupSmoothScrolling() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

// Demo Functions
async function checkText() {
    const text = demoTextarea.value.trim();

    if (!text) {
        showNoErrors();
        return;
    }

    // Show loading state
    resultsContent.innerHTML = `
        <div class="loading">
            <i class="fas fa-spinner fa-spin"></i>
            <p>Checking your text...</p>
        </div>
    `;

    // Analyze text
    const errors = await analyzeText(text);
    displayResults(errors);
}

async function analyzeText(text) {
    // Get selected language from dropdown
    const language = languageDropdown ? languageDropdown.value : 'en-US';
    
    // Call LanguageTool API for real analysis
    try {
        const response = await fetch('http://vmi3028068.contaboserver.net/v2/check', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: `text=${encodeURIComponent(text)}&language=${encodeURIComponent(language)}`
        });

        if (!response.ok) {
            throw new Error(`API error: ${response.status}`);
        }

        const data = await response.json();
        return data.matches.map(match => ({
            word: text.substring(match.offset, match.offset + match.length),
            suggestion: match.replacements.length > 0 ? match.replacements[0].value : null,
            type: match.rule.category.name,
            context: match.rule.description
        }));
    } catch (error) {
        console.error('LanguageTool API error:', error);
        // Fallback to mock analysis if API fails
        return mockAnalyzeText(text);
    }
}

function mockAnalyzeText(text) {
    const commonErrors = [
        { word: 'teh', suggestion: 'the', type: 'spelling' },
        { word: 'sentance', suggestion: 'sentence', type: 'spelling' },
        { word: 'appls', suggestion: 'apples', type: 'spelling' },
        { word: 'Teh', suggestion: 'The', type: 'spelling' },
        { word: 'colour', suggestion: 'color', type: 'spelling', context: 'US English' },
        { word: 'organisation', suggestion: 'organization', type: 'spelling', context: 'US English' }
    ];

    const errors = [];
    const words = text.toLowerCase().split(/\s+/);

    commonErrors.forEach(error => {
        if (text.toLowerCase().includes(error.word.toLowerCase())) {
            errors.push(error);
        }
    });

    return errors;
}

function displayResults(errors) {
    if (errors.length === 0) {
        showNoErrors();
        return;
    }

    resultsCount.textContent = `${errors.length} error${errors.length > 1 ? 's' : ''} found`;

    const resultsHtml = `
        <div class="errors-list">
            ${errors.map(error => `
                <div class="error-item">
                    <div class="error-word">"${error.word}"</div>
                    <div class="error-suggestion">Suggestion: <strong>${error.suggestion}</strong></div>
                    <div class="error-type">${error.type}${error.context ? ` (${error.context})` : ''}</div>
                </div>
            `).join('')}
        </div>
    `;

    resultsContent.innerHTML = resultsHtml;
}

function showNoErrors() {
    resultsCount.textContent = '0 errors found';
    resultsContent.innerHTML = `
        <div class="no-errors">
            <i class="fas fa-check-circle"></i>
            <p>No errors found! Your text looks great.</p>
        </div>
    `;
}

function clearText() {
    demoTextarea.value = '';
    showNoErrors();
}

function loadSampleText() {
    const language = this.value;
    if (sampleTexts[language]) {
        demoTextarea.value = sampleTexts[language];
    }
}

function autoResizeTextarea() {
    this.style.height = 'auto';
    this.style.height = this.scrollHeight + 'px';
}

// Mobile Menu
function toggleMobileMenu() {
    if (navMenu) navMenu.classList.toggle('active');
    if (hamburger) hamburger.classList.toggle('active');
}

// Typing animation for hero
function typeWriter(element, text, speed = 50) {
    let i = 0;
    element.innerHTML = '';

    function type() {
        if (i < text.length) {
            element.innerHTML += text.charAt(i);
            i++;
            setTimeout(type, speed);
        }
    }

    type();
}

// Parallax effect for hero background
window.addEventListener('scroll', function() {
    const scrolled = window.pageYOffset;
    const heroBg = document.querySelector('.hero-bg-pattern');

    if (heroBg) {
        heroBg.style.transform = `translateY(${scrolled * 0.5}px)`;
    }
});

// Form validation (if forms are added later)
function validateForm(form) {
    const inputs = form.querySelectorAll('input, textarea');
    let isValid = true;

    inputs.forEach(input => {
        if (input.hasAttribute('required') && !input.value.trim()) {
            showError(input, 'This field is required');
            isValid = false;
        } else {
            clearError(input);
        }

        if (input.type === 'email' && input.value) {
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(input.value)) {
                showError(input, 'Please enter a valid email address');
                isValid = false;
            }
        }
    });

    return isValid;
}

function showError(input, message) {
    clearError(input);
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-message';
    errorDiv.textContent = message;
    input.parentNode.appendChild(errorDiv);
    input.classList.add('error');
}

function clearError(input) {
    const errorMessage = input.parentNode.querySelector('.error-message');
    if (errorMessage) {
        errorMessage.remove();
    }
    input.classList.remove('error');
}

// Utility functions
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

// Lazy loading for images
function setupLazyLoading() {
    const images = document.querySelectorAll('img[data-src]');

    const imageObserver = new IntersectionObserver((entries, observer) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.classList.remove('lazy');
                observer.unobserve(img);
            }
        });
    });

    images.forEach(img => imageObserver.observe(img));
}

// Accessibility improvements
function setupAccessibility() {
    // Add focus management for mobile menu
    const navLinks = document.querySelectorAll('.nav-link');
    navLinks.forEach(link => {
        link.addEventListener('keydown', function(e) {
            if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                this.click();
            }
        });
    });

    // Add skip to main content link (can be added to HTML)
    const skipLink = document.createElement('a');
    skipLink.href = '#main-content';
    skipLink.className = 'skip-link';
    skipLink.textContent = 'Skip to main content';
    document.body.insertBefore(skipLink, document.body.firstChild);
}

// Performance monitoring
function setupPerformanceMonitoring() {
    // Monitor page load time
    window.addEventListener('load', function() {
        const perfData = performance.getEntriesByType('navigation')[0];
        console.log('Page load time:', perfData.loadEventEnd - perfData.loadEventStart, 'ms');
    });

    // Monitor user interactions
    document.addEventListener('click', debounce(function(e) {
        // Track clicks for analytics
        console.log('User clicked:', e.target.tagName, e.target.className);
    }, 100));
}

// Initialize additional features
setupLazyLoading();
setupAccessibility();
setupPerformanceMonitoring();