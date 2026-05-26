// Smooth scroll for nav links
document.querySelectorAll('a[href^="#"]').forEach(link => {
    link.addEventListener('click', e => {
        e.preventDefault();
        const target = document.querySelector(link.getAttribute('href'));
        if (target) target.scrollIntoView({ behavior: 'smooth' });
    });
});

// Navbar solidify on scroll
const navbar = document.querySelector('.navbar');
function updateNavbar() {
    const isLight = document.body.classList.contains('light');
    const scrolled = window.scrollY > 50;
    if (isLight) {
        navbar.style.background = scrolled ? 'rgba(248, 250, 251, 0.95)' : 'rgba(248, 250, 251, 0.85)';
    } else {
        navbar.style.background = scrolled ? 'rgba(11, 17, 23, 0.95)' : 'rgba(11, 17, 23, 0.8)';
    }
}
window.addEventListener('scroll', updateNavbar);

// Parallax on hero background — scrolls same direction but slower
const hero = document.querySelector('.hero');
window.addEventListener('scroll', () => {
    const offset = 69 + (window.scrollY * 0.3);
    hero.style.backgroundPositionY = `${offset}px`;
});

// Dark/Light theme toggle
const toggle = document.getElementById('themeToggle');
const savedTheme = localStorage.getItem('theme');
if (savedTheme === 'light') document.body.classList.add('light');

toggle.addEventListener('click', () => {
    document.body.classList.toggle('light');
    const isLight = document.body.classList.contains('light');
    localStorage.setItem('theme', isLight ? 'light' : 'dark');
    updateNavbar();
});

// Scroll-triggered animations
const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('visible');
        }
    });
}, { threshold: 0.15 });

// Animate showcase rows
document.querySelectorAll('.showcase-row').forEach(row => {
    const img = row.querySelector('.showcase-image');
    const text = row.querySelector('.showcase-text');
    const isReverse = row.classList.contains('reverse');

    img.style.opacity = '0';
    img.style.transform = isReverse ? 'translateX(40px)' : 'translateX(-40px)';
    img.style.transition = 'opacity 0.7s ease, transform 0.7s ease';

    text.style.opacity = '0';
    text.style.transform = 'translateY(20px)';
    text.style.transition = 'opacity 0.7s ease 0.2s, transform 0.7s ease 0.2s';

    observer.observe(row);
});

// Apply visible state
const style = document.createElement('style');
style.textContent = `
    .showcase-row.visible .showcase-image,
    .showcase-row.visible .showcase-text {
        opacity: 1 !important;
        transform: none !important;
    }
`;
document.head.appendChild(style);
