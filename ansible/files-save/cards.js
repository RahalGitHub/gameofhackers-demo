(() => {
  const cards = [...document.querySelectorAll('.card[data-stream]')];
  const popup = document.getElementById('card-popup');
  if (!popup || !cards.length) return;
  let current = null, hls = null, openTimer, closeTimer;
  const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
  const icon = (name) => ({play:'<polygon points="7 4 20 12 7 20 7 4"/>',plus:'<path d="M12 5v14M5 12h14"/>',check:'<path d="m5 12 4 4L19 6"/>',like:'<path d="M7 10v11H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3Zm0 0 5-8c2-1 3 0 3 2l-1 5h6a2 2 0 0 1 2 2l-2 8a3 3 0 0 1-3 2H7"/>',down:'<path d="m5 9 7 7 7-7"/>',mute:'<path d="M11 5 6 9H3v6h3l5 4V5ZM16 9l5 6m0-6-5 6"/>',sound:'<path d="M11 5 6 9H3v6h3l5 4V5ZM15 9a5 5 0 0 1 0 6M18 6a9 9 0 0 1 0 12"/>'}[name]);
  const svg = name => `<svg viewBox="0 0 24 24" aria-hidden="true">${icon(name)}</svg>`;
  function stopVideo() {
    if (hls) { hls.destroy(); hls = null; }
    const video = popup.querySelector('video');
    if (video) { video.pause(); video.removeAttribute('src'); video.load(); }
  }
  function hide() { clearTimeout(openTimer); clearTimeout(closeTimer); stopVideo(); popup.hidden = true; current = null; }
  function scheduleHide() { clearTimeout(closeTimer); closeTimer = setTimeout(hide, 220); }
  function link(card) {
    const url = new URL('watch-dash.html', location.href);
    url.searchParams.set('src', card.dataset.stream);
    url.searchParams.set('title', `${card.dataset.title} — ${card.dataset.variant}`);
    location.assign(url.href);
  }
  function preview(card) {
    const video = popup.querySelector('video');
    if (!video || !card.dataset.stream) return;
    video.muted = true; video.playsInline = true;
    const play = () => video.play().then(() => video.classList.add('playing')).catch(() => {});
    if (window.Hls && Hls.isSupported()) {
      hls = new Hls(); hls.loadSource(card.dataset.stream); hls.attachMedia(video);
      hls.on(Hls.Events.MANIFEST_PARSED, play);
    } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
      video.src = card.dataset.stream; video.addEventListener('loadedmetadata', play, {once:true});
    }
  }
  function show(card) {
    clearTimeout(openTimer); clearTimeout(closeTimer);
    if (current === card && !popup.hidden) return;
    stopVideo(); current = card;
    const img = card.querySelector('img');
    const d = card.dataset;
    popup.innerHTML = `<div class="popup-media"><img src="${esc(img?.getAttribute('src'))}" alt=""><video muted playsinline preload="none"></video><div class="popup-gradient"></div><div class="popup-brand"><h3>${esc(d.title || 'SUNFLOWER')}</h3><span>${esc(d.variant || '')}</span></div><button class="popup-btn popup-sound" type="button" aria-label="Activer le son">${svg('mute')}</button></div><div class="popup-body"><div class="popup-kind">Film <span class="sep">|</span> Animation • Comédie</div><div class="popup-meta"><span>${esc(d.year || '2026')}</span><span class="dot">•</span><span class="popup-pill">${esc(d.rating || 'Tous publics')}</span><span class="popup-pill">HD</span><span class="popup-pill">${esc(d.resolution || '1080p')}</span></div><div class="popup-variant">${esc(d.fps || '')} <span>•</span> ${esc(d.audio || '')} <span>•</span> Court-métrage</div><div class="popup-actions"><button class="popup-btn popup-play" type="button" aria-label="Lecture" title="Lecture">${svg('play')}</button><button class="popup-btn popup-add" type="button" aria-label="Ajouter à ma liste" title="Ajouter à ma liste">${svg('plus')}</button><button class="popup-btn popup-like" type="button" aria-label="J'aime" title="J'aime">${svg('like')}</button><button class="popup-btn popup-info" type="button" aria-label="Détails et lecture" title="Détails et lecture">${svg('down')}</button></div></div>`;
    popup.hidden = false;
    const r = card.getBoundingClientRect(), width = popup.offsetWidth, height = popup.offsetHeight;
    popup.style.left = `${Math.max(12, Math.min(innerWidth-width-12,r.left+r.width/2-width/2))}px`;
    popup.style.top = `${Math.max(12, Math.min(innerHeight-height-12,r.top+r.height/2-height/2))}px`;
    popup.querySelector('.popup-play').addEventListener('click', () => link(card));
    popup.querySelector('.popup-info').addEventListener('click', () => link(card));
    popup.querySelector('.popup-add').addEventListener('click', e => { const active = e.currentTarget.getAttribute('aria-pressed') !== 'true'; e.currentTarget.setAttribute('aria-pressed',String(active)); e.currentTarget.innerHTML=svg(active?'check':'plus'); });
    popup.querySelector('.popup-like').addEventListener('click', e => { const active=e.currentTarget.getAttribute('aria-pressed')!=='true';e.currentTarget.setAttribute('aria-pressed',String(active));e.currentTarget.style.color=active?'#46d369':''; });
    popup.querySelector('.popup-sound').addEventListener('click', e => { const v=popup.querySelector('video');v.muted=!v.muted;e.currentTarget.innerHTML=svg(v.muted?'mute':'sound');e.currentTarget.setAttribute('aria-label',v.muted?'Activer le son':'Couper le son'); });
    preview(card);
  }
  cards.forEach(card => {
    card.addEventListener('mouseenter', () => { clearTimeout(closeTimer); clearTimeout(openTimer);openTimer=setTimeout(()=>show(card),350); });
    card.addEventListener('mouseleave', () => {clearTimeout(openTimer);scheduleHide();});
    card.addEventListener('focus', () => show(card));
    card.addEventListener('keydown', e => {if(e.key==='Enter'){e.preventDefault();link(card);}if(e.key==='Escape')hide();});
    card.addEventListener('click', () => link(card));
  });
  popup.addEventListener('mouseenter', () => clearTimeout(closeTimer));
  popup.addEventListener('mouseleave', scheduleHide);
  document.addEventListener('keydown', e => {if(e.key==='Escape')hide();});
  window.addEventListener('scroll', hide, {passive:true});
  window.addEventListener('resize', hide);
  window.addEventListener('pagehide', hide);
})();
