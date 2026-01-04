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
    
    // Initialize time shortcut demo
    initTimeShortcutDemo();
});

// Initialize time shortcut demo
function initTimeShortcutDemo() {
    const input = document.getElementById('time-shortcut-demo');
    const button = document.getElementById('apply-shortcut');
    const result = document.getElementById('shortcut-result');
    
    // Apply shortcut when button is clicked
    button.addEventListener('click', () => {
        applyTimeShortcut(input, result);
    });
    
    // Apply shortcut when Enter key is pressed
    input.addEventListener('keypress', (e) => {
        if (e.key === 'Enter') {
            applyTimeShortcut(input, result);
        }
    });
}

// Apply time shortcut and show result
function applyTimeShortcut(input, resultElement) {
    const shortcut = input.value.trim();
    if (!shortcut) {
        resultElement.innerHTML = '<div class="alert alert-info">Please enter a shortcut like +1d, +1w, or +1m</div>';
        return;
    }
    
    // Parse shortcut
    const now = new Date();
    let calculatedDate = new Date(now);
    let isValid = false;
    let description = '';
    
    // Check for different shortcut formats
    const shortcuts = [
        { regex: /^\+?(\d+)d$/i, days: 1, desc: 'day' },
        { regex: /^\+?(\d+)w$/i, days: 7, desc: 'week' },
        { regex: /^\+?(\d+)m$/i, days: 30, desc: 'month' }
    ];
    
    for (const s of shortcuts) {
        const match = shortcut.match(s.regex);
        if (match) {
            const count = parseInt(match[1], 10);
            calculatedDate.setDate(now.getDate() + count * s.days);
            description = `${count} ${s.desc}${count > 1 ? 's' : ''}`;
            isValid = true;
            break;
        }
    }
    
    if (isValid) {
        // Format the date
        const options = { year: 'numeric', month: 'long', day: 'numeric' };
        const formattedDate = calculatedDate.toLocaleDateString(document.documentElement.lang === 'zh' ? 'zh-CN' : 'en-US', options);
        
        // Show result
        resultElement.innerHTML = `
            <div class="alert alert-success">
                <strong>Success!</strong> ${shortcut} = ${description} later<br>
                <strong>Due date:</strong> ${formattedDate}
            </div>
        `;
    } else {
        // Invalid shortcut
        resultElement.innerHTML = '<div class="alert alert-danger">Invalid shortcut. Please use +1d, +1w, or +1m format.</div>';
    }
}