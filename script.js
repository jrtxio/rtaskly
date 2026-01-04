// Language Switcher Script

// Initialize language
function initLanguage() {
    // Get saved language from localStorage, or use browser default
    const savedLang = localStorage.getItem('preferredLanguage');
    const browserLang = navigator.language.split('-')[0];
    const initialLang = savedLang || browserLang || 'en';
    
    // Set initial language
    setLanguage(initialLang);
}

// Set language for the page
function setLanguage(lang) {
    // Update language buttons
    document.getElementById('lang-en').classList.toggle('active', lang === 'en');
    document.getElementById('lang-zh').classList.toggle('active', lang === 'zh');
    
    // Save preference to localStorage
    localStorage.setItem('preferredLanguage', lang);
    
    // Update document lang attribute
    document.documentElement.lang = lang;
    
    // Update page title
    const titleElement = document.querySelector('title');
    if (lang === 'zh') {
        titleElement.textContent = 'Taskly - 一个使用 Racket 构建的简单直观的任务管理器';
    } else {
        titleElement.textContent = 'Taskly - Simple and Intuitive Task Manager';
    }
    
    // Update all elements with data-en and data-zh attributes
    const elements = document.querySelectorAll('[data-en][data-zh]');
    elements.forEach(element => {
        element.textContent = element.getAttribute(`data-${lang}`);
    });
}

// Event listeners for language buttons
document.addEventListener('DOMContentLoaded', () => {
    // Initialize language
    initLanguage();
    
    // Add click listeners to language buttons
    document.getElementById('lang-en').addEventListener('click', () => {
        setLanguage('en');
    });
    
    document.getElementById('lang-zh').addEventListener('click', () => {
        setLanguage('zh');
    });
});