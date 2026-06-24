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

// Editorial last-updated date (update manually when content changes)
const LAST_UPDATED = 'June 2026';
document.querySelectorAll('#last-updated').forEach(el => { el.textContent = LAST_UPDATED; });

// Footer copyright year — dynamic
const footerYear = document.getElementById('footer-year');
if (footerYear) footerYear.textContent = new Date().getFullYear();
