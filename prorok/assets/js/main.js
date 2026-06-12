(function () {
  function trackAndOpenTelegram(link) {
    const page = location.pathname;
    const cta = link.dataset.cta || 'unknown';
    const section = link.dataset.section || 'unknown';

    const source = page.replace(/^\/+|\/+$/g, '').replace(/\//g, '_') || 'home';
    const telegramUrl = `https://t.me/SprosiProroka_bot?start=${encodeURIComponent(source)}`;

    if (typeof window.gtag === 'function') {
      window.gtag('event', 'telegram_click', {
        page_location: location.href,
        page_path: page,
        cta_name: cta,
        section: section,
        outbound_url: telegramUrl,
        transport_type: 'beacon'
      });
    }

    setTimeout(() => {
      window.open(telegramUrl, '_blank', 'noopener');
    }, 150);
  }

  document.addEventListener('click', (e) => {
    const link = e.target.closest('.js-telegram-cta');
    if (!link) return;

    e.preventDefault();
    trackAndOpenTelegram(link);
  });
})();
