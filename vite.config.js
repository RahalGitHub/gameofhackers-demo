import { defineConfig } from "vite";

export default defineConfig({
  root: "ansible/files",

  build: {
    rollupOptions: {
      input: {
        login: "ansible/files/login.html",
        profiles: "ansible/files/index.html",
        game: "ansible/files/jeux.html",
        home: "ansible/files/home.html",
        watch: "ansible/files/watch.html",
        watchDash: "ansible/files/watch-dash.html",
        animx: "ansible/files/animx.html",
        player: "ansible/files/player.js",
        cards: "ansible/files/cards.js",
        watchDashJs: "ansible/files/watch-dash.js",
      },
    },
    outDir: "../../dist",
    emptyOutDir: true,
  },
});