/**
 * Red Grid Tactical — Site Script
 * Vanilla JS, no dependencies.
 * Runs on all pages; guards against missing elements.
 */
document.addEventListener('DOMContentLoaded', () => {

  // ─── Mobile Navigation ───────────────────────────────────────────
  const hamburger = document.querySelector('.nav-hamburger');
  const menu = document.querySelector('.nav-menu');
  const overlay = document.querySelector('.nav-overlay');

  function closeMenu() {
    if (menu) menu.classList.remove('open');
    if (overlay) overlay.classList.remove('open');
    if (hamburger) hamburger.classList.remove('active');
  }

  if (hamburger && menu) {
    hamburger.addEventListener('click', () => {
      const isOpen = menu.classList.toggle('open');
      hamburger.classList.toggle('active', isOpen);
      if (overlay) overlay.classList.toggle('open', isOpen);
    });
  }

  // Close menu when overlay is clicked
  if (overlay) {
    overlay.addEventListener('click', closeMenu);
  }

  // Close menu when a nav link is clicked (but not submenu toggles)
  if (menu) {
    menu.addEventListener('click', (e) => {
      const link = e.target.closest('a');
      if (link && !link.classList.contains('submenu-toggle')) {
        closeMenu();
      }
    });
  }

  // ─── Submenu Toggle ("Our Apps" dropdown) ────────────────────────
  document.querySelectorAll('.submenu-toggle').forEach((toggle) => {
    toggle.addEventListener('click', (e) => {
      e.preventDefault();
      const group = toggle.closest('.submenu-group');
      if (group) {
        group.classList.toggle('open');
      }
    });
  });

  // ─── Scroll Fade-In Animations ───────────────────────────────────
  const fadeEls = document.querySelectorAll('.fade-in');

  if (fadeEls.length > 0 && 'IntersectionObserver' in window) {
    const fadeObserver = new IntersectionObserver(
      (entries, observer) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('visible');
            observer.unobserve(entry.target);
          }
        });
      },
      { threshold: 0.1 }
    );

    fadeEls.forEach((el) => fadeObserver.observe(el));
  } else {
    // Fallback: make everything visible immediately
    fadeEls.forEach((el) => el.classList.add('visible'));
  }

  // ─── Sticky Nav Background ──────────────────────────────────────
  const nav = document.querySelector('.nav');

  if (nav) {
    const updateNav = () => {
      nav.classList.toggle('scrolled', window.scrollY > 50);
    };
    window.addEventListener('scroll', updateNav, { passive: true });
    updateNav(); // set initial state
  }

  // ─── FAQ Accordion (close siblings on open) ─────────────────────
  const faqItems = document.querySelectorAll('.faq-item');

  if (faqItems.length > 0) {
    faqItems.forEach((item) => {
      item.addEventListener('toggle', () => {
        if (item.open) {
          // Close all other open FAQ items
          faqItems.forEach((sibling) => {
            if (sibling !== item && sibling.open) {
              sibling.open = false;
            }
          });
        }
      });
    });
  }

  // ─── Contact Form Handling ──────────────────────────────────────
  const contactForm = document.querySelector('.contact-form');

  if (contactForm) {
    // Create status element if it doesn't already exist
    let statusEl = contactForm.querySelector('.form-status');
    if (!statusEl) {
      statusEl = document.createElement('div');
      statusEl.className = 'form-status';
      contactForm.appendChild(statusEl);
    }

    contactForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      statusEl.textContent = '';
      statusEl.className = 'form-status';

      const data = new FormData(contactForm);
      const action = contactForm.action;

      if (!action) {
        statusEl.textContent = 'Form endpoint not configured.';
        statusEl.classList.add('error');
        return;
      }

      try {
        const res = await fetch(action, {
          method: 'POST',
          body: data,
          headers: { Accept: 'application/json' },
        });

        if (res.ok) {
          statusEl.textContent = 'Message sent! We\'ll get back to you soon.';
          statusEl.classList.add('success');
          contactForm.reset();
        } else {
          const body = await res.json().catch(() => null);
          const msg =
            body && body.errors
              ? body.errors.map((err) => err.message).join(', ')
              : 'Something went wrong. Please try again.';
          statusEl.textContent = msg;
          statusEl.classList.add('error');
        }
      } catch {
        statusEl.textContent = 'Network error. Please check your connection and try again.';
        statusEl.classList.add('error');
      }
    });
  }

  // ─── Smooth Scroll for Anchor Links ─────────────────────────────
  document.addEventListener('click', (e) => {
    const link = e.target.closest('a[href^="#"]');
    if (!link) return;

    const targetId = link.getAttribute('href');
    if (targetId === '#' || targetId.length < 2) return;

    const target = document.querySelector(targetId);
    if (!target) return;

    e.preventDefault();

    const navHeight = nav ? nav.offsetHeight : 0;
    const top = target.getBoundingClientRect().top + window.scrollY - navHeight;

    window.scrollTo({ top, behavior: 'smooth' });

    // Update URL hash without jumping
    history.pushState(null, '', targetId);
  });

  // ─── Roadmap Tab Toggle ─────────────────────────────────────────
  const tabContainer = document.querySelector('.roadmap-tabs');

  if (tabContainer) {
    tabContainer.addEventListener('click', (e) => {
      const tab = e.target.closest('[data-tab]');
      if (!tab) return;

      const targetId = tab.dataset.tab;

      // Update active tab
      tabContainer.querySelectorAll('[data-tab]').forEach((t) => {
        t.classList.toggle('active', t === tab);
      });

      // Show matching timeline, hide others
      document.querySelectorAll('.timeline').forEach((timeline) => {
        timeline.classList.toggle(
          'active',
          timeline.id === targetId || timeline.dataset.tab === targetId
        );
      });
    });
  }
});
