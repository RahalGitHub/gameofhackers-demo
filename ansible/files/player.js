const HLS_URL = "/stream/hls/stream.m3u8";

const heroVideo = document.getElementById("heroVideo");
const video = document.getElementById("video");
const status = document.getElementById("status");
const playButton = document.getElementById("playButton");
const soundButton = document.getElementById("soundButton");
const infoButton = document.getElementById("infoButton");

let hls = null;

function setStatus(message, ok = false) {
  if (!status) return;
  status.textContent = message;
  status.style.color = ok ? "#46d369" : "#aaa";
}

function loadProfile() {
  const profile = new URLSearchParams(window.location.search).get("profile");
  const profileName = document.getElementById("profileName");
  if (profile && profileName) profileName.textContent = profile;
}

function setupVideo(videoElement) {
  if (!videoElement) return null;

  if (window.Hls && Hls.isSupported()) {
    const instance = new Hls();
    instance.loadSource(HLS_URL);
    instance.attachMedia(videoElement);

    instance.on(Hls.Events.MANIFEST_PARSED, () => {
      if (videoElement === heroVideo) {
        videoElement.play().catch(() => {});
      }
      setStatus("Flux HLS connecté ✓", true);
    });

    instance.on(Hls.Events.ERROR, (_, data) => {
      console.error("Erreur HLS :", data);
      setStatus("Erreur HLS — vérifie le flux et le réseau.");
    });

    return instance;
  }

  if (videoElement.canPlayType("application/vnd.apple.mpegurl")) {
    videoElement.src = HLS_URL;
    videoElement.addEventListener("loadedmetadata", () => {
      if (videoElement === heroVideo) {
        videoElement.play().catch(() => {});
      }
      setStatus("Flux HLS connecté ✓", true);
    });
    return null;
  }

  setStatus("HLS n'est pas supporté par ce navigateur.");
  return null;
}

function syncPlayer() {
  if (!heroVideo || !video) return;

  if (heroVideo.src && !video.src) {
    video.src = heroVideo.src;
  }
}

function openPlayer() {
  if (!heroVideo) return;

  heroVideo.play().catch(() => {});
  heroVideo.scrollIntoView({ behavior: "smooth", block: "center" });
}

function updateSoundIcon() {
  if (!soundButton || !heroVideo) return;
  const icon = soundButton.querySelector(".x-icon");
  if (icon) {
    icon.classList.toggle("x-icon-volume-off", heroVideo.muted);
    icon.classList.toggle("x-icon-volume-on", !heroVideo.muted);
  }
  soundButton.setAttribute("aria-label", heroVideo.muted ? "Activer le son" : "Couper le son");
}

function toggleSound() {
  if (!heroVideo) return;

  heroVideo.muted = !heroVideo.muted;
  updateSoundIcon();
  soundButton.setAttribute(
    "aria-label",
    heroVideo.muted ? "Activer le son" : "Couper le son"
  );

  if (!heroVideo.muted) {
    heroVideo.play().catch(() => {});
  }
}

document.addEventListener("DOMContentLoaded", () => {
  loadProfile();
  updateSoundIcon();

  hls = setupVideo(heroVideo);
  setupVideo(video);
/*
  if (playButton) {
    playButton.addEventListener("click", () => {
      if (heroVideo) {
        heroVideo.muted = false;
        heroVideo.play().catch(() => {});
        updateSoundIcon();
      }
    });
  }
*/

if (playButton) {
  playButton.addEventListener("click", () => {
    window.location.href = "watch.html";
  });
}

  if (soundButton) {
    soundButton.addEventListener("click", toggleSound);
  }

  if (infoButton) {
    infoButton.addEventListener("click", () => {
      document.getElementById("selection")?.scrollIntoView({
        behavior: "smooth"
      });
    });
  }

  syncPlayer();
});
