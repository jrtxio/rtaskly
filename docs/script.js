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
    
    // Initialize mobile menu
    initMobileMenu();
});

// Initialize mobile menu
function initMobileMenu() {
    const mobileMenuBtn = document.querySelector('.mobile-menu-btn');
    const navMenu = document.querySelector('.nav-menu');
    
    // Toggle menu on button click
    mobileMenuBtn.addEventListener('click', () => {
        mobileMenuBtn.classList.toggle('active');
        navMenu.classList.toggle('active');
    });
    
    // Close menu when clicking outside
    document.addEventListener('click', (e) => {
        if (!mobileMenuBtn.contains(e.target) && !navMenu.contains(e.target)) {
            mobileMenuBtn.classList.remove('active');
            navMenu.classList.remove('active');
        }
    });
    
    // Close menu when clicking on a nav link
    const navLinks = navMenu.querySelectorAll('a');
    navLinks.forEach(link => {
        link.addEventListener('click', () => {
            mobileMenuBtn.classList.remove('active');
            navMenu.classList.remove('active');
        });
    });
}

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
    
    // Add click listeners to shortcut buttons
    const shortcutButtons = document.querySelectorAll('.shortcut-btn');
    shortcutButtons.forEach(btn => {
        btn.addEventListener('click', () => {
            const shortcut = btn.getAttribute('data-shortcut');
            input.value = shortcut;
            applyTimeShortcut(input, result);
        });
    });
}

// Apply time shortcut and show result
function applyTimeShortcut(input, resultElement) {
    const shortcut = input.value.trim();
    if (!shortcut) {
        resultElement.innerHTML = '<div class="alert alert-info">Please enter a shortcut like +30m, +1h, +1d, +1w, or +1M</div>';
        return;
    }
    
    // Parse shortcut
    const now = new Date();
    let calculatedDate = new Date(now);
    let isValid = false;
    let description = '';
    
    // Check for different shortcut formats
    const match = shortcut.match(/^\+?([0-9]+)([dmhwM])$/i);
    
    if (match) {
        const count = parseInt(match[1], 10);
        const unit = match[2].toLowerCase();
        const unitUpper = match[2];
        
        switch (unitUpper) {
            case 'm':
                // Minutes
                calculatedDate.setMinutes(now.getMinutes() + count);
                description = `${count} minute${count > 1 ? 's' : ''}`;
                isValid = true;
                break;
            case 'h':
                // Hours
                calculatedDate.setHours(now.getHours() + count);
                description = `${count} hour${count > 1 ? 's' : ''}`;
                isValid = true;
                break;
            case 'd':
                // Days
                calculatedDate.setDate(now.getDate() + count);
                description = `${count} day${count > 1 ? 's' : ''}`;
                isValid = true;
                break;
            case 'w':
                // Weeks
                calculatedDate.setDate(now.getDate() + (count * 7));
                description = `${count} week${count > 1 ? 's' : ''}`;
                isValid = true;
                break;
            case 'M':
                // Months
                const currentMonth = now.getMonth();
                const newMonth = currentMonth + count;
                const yearOffset = Math.floor(newMonth / 12);
                const finalMonth = newMonth % 12;
                const finalYear = now.getFullYear() + yearOffset;
                
                // Set to same day or last day of month if day doesn't exist
                const lastDay = new Date(finalYear, finalMonth + 1, 0).getDate();
                const finalDay = Math.min(now.getDate(), lastDay);
                
                calculatedDate = new Date(finalYear, finalMonth, finalDay, now.getHours(), now.getMinutes());
                description = `${count} month${count > 1 ? 's' : ''}`;
                isValid = true;
                break;
        }
    }
    
    if (isValid) {
        // Format the date
        const options = { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' };
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
        resultElement.innerHTML = '<div class="alert alert-danger">Invalid shortcut. Please use +30m, +1h, +1d, +1w, or +1M format.</div>';
    }
}