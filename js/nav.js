// Mobile nav toggle
const btn = document.querySelector('.nav-toggle');
const nav = document.querySelector('.site-nav');
btn?.addEventListener('click', () => {
  const open = btn.getAttribute('aria-expanded') === 'true';
  btn.setAttribute('aria-expanded', String(!open));
  nav.classList.toggle('is-open');
});

// Close nav on outside click
document.addEventListener('click', (e) => {
  if (nav?.classList.contains('is-open') && !e.target.closest('.site-header')) {
    btn?.setAttribute('aria-expanded', 'false');
    nav.classList.remove('is-open');
  }
});

// Inject current date into footer
const now = new Date();
const year = now.getFullYear();
const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];

const lastUpdated = document.getElementById('last-updated');
if (lastUpdated) lastUpdated.textContent = `${months[now.getMonth()]} ${year}`;

const footerYear = document.getElementById('footer-year');
if (footerYear) footerYear.textContent = year;
