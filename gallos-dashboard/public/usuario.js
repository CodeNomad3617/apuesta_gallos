const firebaseConfig = {
  apiKey: "AIzaSyBnj2i68BldCgnbBHchwWIiAWmGsETuTR4",
  authDomain: "gallos-app-6ac95.firebaseapp.com",
  projectId: "gallos-app-6ac95",
  storageBucket: "gallos-app-6ac95.firebasestorage.app",
  messagingSenderId: "1026205994287",
  appId: "1:1026205994287:web:860938c1c7eeaa8c42a5da",
  measurementId: "G-VHBD6Q99B4"
};

firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

const params = new URLSearchParams(window.location.search);
const id = params.get("id");

const resumenDiv = document.getElementById("resumen");

if (!id) {
  resumenDiv.innerHTML = "<p>Falta el ID del usuario en la URL. Usa: usuario.html?id=peque123</p>";
} else {
  db.collection("usuarios").doc(id).get().then(doc => {
    if (!doc.exists) {
      resumenDiv.innerHTML = "<p>Usuario no encontrado.</p>";
      return;
    }

    const data = doc.data();
    const apuestas = data.apuestas || [];

    resumenDiv.innerHTML = `
      <p><strong>Nombre:</strong> ${data.nombre}</p>
      <p><strong>Saldo inicial:</strong> $${data.saldoInicial}</p>
      <p><strong>Saldo actual:</strong> $${data.saldoActual}</p>
      <h3>Apuestas:</h3>
      <ul>
        ${apuestas.map(apuesta => `
          <li>
            🥊 <strong>Pelea ${apuesta.pelea}</strong> - Color: ${apuesta.color} - Monto: $${apuesta.monto} - Resultado: ${apuesta.resultado}
          </li>
        `).join("")}
      </ul>
    `;
  }).catch(err => {
    resumenDiv.innerHTML = `<p>Error: ${err.message}</p>`;
  });
}
