(async function () {
  const API_KEY = 'AIzaSyAY3hxy7uGTIyWneh_shR-0oCm8ZZaPwiQ';
  const cards = document.querySelectorAll('[data-place-id]:not([data-place-id="static"])');

  async function fetchPlace(placeId) {
    const controller = new AbortController();
    const tid = setTimeout(() => controller.abort(), 5000);
    try {
      const res = await fetch(`https://places.googleapis.com/v1/places/${placeId}?languageCode=en`, {
        headers: {
          'X-Goog-Api-Key': API_KEY,
          'X-Goog-FieldMask': 'rating,userRatingCount,reviews'
        },
        signal: controller.signal
      });
      clearTimeout(tid);
      if (!res.ok) return null;
      return res.json();
    } catch {
      clearTimeout(tid);
      return null;
    }
  }

  function starsHtml(rating) {
    const full = Math.round(rating);
    return '★'.repeat(full) + '☆'.repeat(5 - full);
  }

  function renderReview(r) {
    const text = r.text?.text || '';
    const summary = text.slice(0, 140);
    const needsTruncation = text.length > 140;
    return `<div class="review-item">
      <div class="review-meta">
        <span class="reviewer-name">${r.authorAttribution?.displayName || 'Traveler'}</span>
        <span class="review-stars">${starsHtml(r.rating || 5)}</span>
        <span class="review-date">${r.relativePublishTimeDescription || ''}</span>
      </div>
      ${needsTruncation
        ? `<details class="review-text-wrapper"><summary>${summary}…</summary><p>${text}</p></details>`
        : `<p style="font-size:0.875rem;color:var(--text-secondary);margin:0;line-height:1.6">${text}</p>`
      }
    </div>`;
  }

  for (const card of cards) {
    const placeId = card.dataset.placeId;
    const data = await fetchPlace(placeId);
    if (!data) continue;

    if (data.rating) {
      card.querySelectorAll('.stars[data-rating]').forEach(el => {
        el.textContent = starsHtml(data.rating);
      });
      card.querySelectorAll('[data-rating]').forEach(el => {
        if (el.classList.contains('rating-number')) {
          el.textContent = data.rating.toFixed(1);
        }
      });
    }

    if (data.userRatingCount) {
      const countEl = card.querySelector('[data-review-count]');
      if (countEl) countEl.textContent = `${data.userRatingCount.toLocaleString()} Google reviews`;
    }

    if (data.reviews?.length) {
      const listEl = card.querySelector('[data-reviews-list]');
      if (listEl) {
          const englishReviews = data.reviews.filter(r =>
          !/[Ѐ-ӿ]/.test(r.text?.text || '') && (r.rating || 5) >= 4
        );
        const toShow = englishReviews.length >= 2 ? englishReviews : data.reviews.filter(r => (r.rating || 5) >= 4);
        listEl.innerHTML = toShow.slice(0, 5).map(renderReview).join('');
      }
    }
  }
})();
