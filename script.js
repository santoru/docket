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
window.addEventListener('scroll', () => {
    navbar.style.background = window.scrollY > 50
        ? 'rgba(11, 17, 23, 0.95)'
        : 'rgba(11, 17, 23, 0.8)';
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

// Animate mini features
document.querySelectorAll('.mini-feature').forEach((el, i) => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(20px)';
    el.style.transition = `opacity 0.5s ease ${i * 0.1}s, transform 0.5s ease ${i * 0.1}s`;
    observer.observe(el);
});

// Apply visible state
const style = document.createElement('style');
style.textContent = `
    .showcase-row.visible .showcase-image,
    .showcase-row.visible .showcase-text,
    .mini-feature.visible {
        opacity: 1 !important;
        transform: none !important;
    }
`;
document.head.appendChild(style);
