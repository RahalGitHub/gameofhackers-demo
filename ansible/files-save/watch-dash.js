// Même logique que watch.js ; conserve la sélection de la vignette.
const video = document.getElementById('movie');
const message = document.getElementById('message');
const intro = document.getElementById('intro');
const params = new URLSearchParams(window.location.search);
const requested = params.get('src') || '/stream/hls/stream.m3u8';
const source = /^\/stream\/hls\/[a-zA-Z0-9_./-]+\.m3u8$/.test(requested) && !requested.includes('..')
  ? requested : '/stream/hls/stream.m3u8';
const title = params.get('title');
if (title) document.title = `${title} — X-STREAM`;
let hls;
function error(text) { message.textContent = text; }
function startPlayback() {
  video.play().catch(() => error('Appuyez sur Lecture pour démarrer la vidéo.'));
}
function setupStream() {
  if (window.Hls && Hls.isSupported()) {
    hls = new Hls();
    hls.loadSource(source);
    hls.attachMedia(video);
    hls.on(Hls.Events.MANIFEST_PARSED, () => {
      message.textContent = '';
      startPlayback();
    });
    hls.on(Hls.Events.ERROR, (_, data) => {
      if (!data.fatal) return;
      if (data.type === Hls.ErrorTypes.NETWORK_ERROR) {
        error('Connexion au flux interrompue. Nouvelle tentative…');
        hls.startLoad();
      } else if (data.type === Hls.ErrorTypes.MEDIA_ERROR) {
        hls.recoverMediaError();
      } else {
        error('Impossible de lire ce flux vidéo.');
        hls.destroy();
        hls = null;
      }
    });
  } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
    video.src = source;
    video.addEventListener('loadedmetadata', startPlayback, { once: true });
  } else {
    error('Votre navigateur ne prend pas en charge la lecture HLS.');
  }
  video.addEventListener('playing', () => { message.textContent = ''; });
  video.addEventListener('error', () => error('Impossible de charger la vidéo. Vérifiez le serveur HLS.'));
}
setupStream();
// Exactement comme watch.js : on retire l'overlay à la fin de intro-out.
intro.addEventListener('animationend', e => {
  if (e.target === intro && e.animationName === 'intro-out') intro.remove();
});
window.addEventListener('pagehide', () => { if (hls) hls.destroy(); });
