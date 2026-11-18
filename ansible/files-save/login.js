import { Amplify } from "aws-amplify";
import { signIn, signOut, getCurrentUser } from "aws-amplify/auth";
import { cognitoConfig } from "./cognito-config.js";

Amplify.configure(cognitoConfig);

const form = document.getElementById("login-form");
const message = document.getElementById("message");

// Vérifie si une session Cognito existe déjà
async function checkExistingSession() {
  try {
    await getCurrentUser();

    // Une session existe déjà
    console.log("Session Cognito déjà active.");

    // On reste sur login.html pour permettre à l'utilisateur
    // de choisir son profil après authentification.
  } catch (error) {
    // Aucun utilisateur connecté : comportement normal.
  }
}

checkExistingSession();

form.addEventListener("submit", async (event) => {
  event.preventDefault();

  const email = document.getElementById("email").value.trim();
  const password = document.getElementById("password").value;

  message.textContent = "Connexion en cours...";
  message.className = "message";

  try {
    // Si une session existe déjà, on la ferme avant
    // de permettre une nouvelle connexion.
    try {
      await getCurrentUser();
      await signOut();
    } catch {
      // Pas de session active : rien à faire.
    }

    const { isSignedIn } = await signIn({
      username: email,
      password,
    });

    if (isSignedIn) {
      message.textContent = "Connexion réussie.";
      message.className = "message success";

      // IMPORTANT :
      // Après authentification, on va vers la page des profils,
      // pas directement vers la page vidéo.
      window.location.href = "index.html";
      return;
    }

    message.textContent =
      "Une étape supplémentaire est nécessaire pour terminer la connexion.";
  } catch (error) {
    console.error("Erreur Cognito :", error);

    if (
      error.name === "NotAuthorizedException" ||
      error.name === "UserNotFoundException"
    ) {
      message.textContent =
        "Adresse e-mail ou mot de passe incorrect.";
    } else if (error.name === "UserNotConfirmedException") {
      message.textContent =
        "Votre compte doit être confirmé.";
    } else {
      message.textContent =
        "Impossible de se connecter. Vérifiez vos informations.";
    }

    message.className = "message error";
  }
});
