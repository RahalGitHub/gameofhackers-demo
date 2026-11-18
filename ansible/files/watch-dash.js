
const video = document.getElementById('movie');
const message = document.getElementById('message');
const intro = document.getElementById('intro');

const params = new URLSearchParams(window.location.search);
const requested = params.get('src') || '/stream/dash/stream.mpd';

const source =
  /^\/stream\/dash\/[a-zA-Z0-9_./-]+\.mpd$/.test(requested) &&
  !requested.includes('..')
    ? requested
    : '/stream/dash/stream.mpd';

const title = params.get('title');
if (title) document.title = `${title} — GAMEOFHACKERS`;

let player = null;

function error(text) {
  message.textContent = text;
}

function startPlayback() {
  video.play().catch(() => {
    error('Appuyez sur Lecture pour démarrer la vidéo.');
  });
}

function setupStream() {
  if (!window.dashjs) {
    error('Impossible de charger le lecteur DASH.');
    return;
  }

  player = dashjs.MediaPlayer().create();

  player.on(dashjs.MediaPlayer.events.STREAM_INITIALIZED, () => {
    message.textContent = '';
    startPlayback();
  });

  player.on(dashjs.MediaPlayer.events.ERROR, () => {
    error('Erreur de lecture DASH. Vérifiez que FFmpeg diffuse la vidéo.');
  });

  player.initialize(video, source, false);

  video.addEventListener('playing', () => {
    message.textContent = '';
  });

  video.addEventListener('error', () => {
    error('Impossible de charger la vidéo DASH.');
  });
}

setupStream();

// Conserver l'animation GAMEOFHACKERS existante.
intro.addEventListener('animationend', e => {
  if (e.target === intro && e.animationName === 'intro-out') {
    intro.remove();
  }
});

// Libérer le lecteur en quittant la page.
window.addEventListener('pagehide', () => {
  if (player) {
    player.destroy();
    player = null;
  }
});
