/* Catalogue des supports : lit catalogue.json (généré par scripts/construire.py)
   et construit la page. Aucune dépendance, aucune étape de compilation. */
"use strict";

const $ = (sel, el = document) => el.querySelector(sel);
const etat = { q: "", composante: "", donnees: null };

const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) =>
  ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));

const sansAccents = (s) => String(s ?? "").normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();

const dateCourte = (iso) => {
  if (!iso) return "";
  const d = new Date(iso + "T12:00:00");
  return isNaN(d) ? iso : d.toLocaleDateString("fr-FR", { day: "numeric", month: "short", year: "numeric" });
};

const taille = (n) => {
  if (!n) return "";
  const u = ["o", "Ko", "Mo", "Go"];
  let i = 0;
  while (n >= 1024 && i < u.length - 1) { n /= 1024; i++; }
  return (i === 0 ? n : n.toFixed(1).replace(".", ",")) + "\u00a0" + u[i];
};

const pluriel = (n, un, plusieurs) => `${n}\u00a0${n > 1 ? plusieurs : un}`;

/* Surligne les termes recherchés dans un texte déjà échappé */
function surligner(texte) {
  const brut = esc(texte);
  if (!etat.q) return brut;
  const cible = sansAccents(etat.q).trim();
  if (!cible) return brut;
  const norm = sansAccents(texte);
  const i = norm.indexOf(cible);
  if (i < 0) return brut;
  return esc(texte.slice(0, i)) + "<mark>" + esc(texte.slice(i, i + cible.length)) + "</mark>" +
         esc(texte.slice(i + cible.length));
}

/* ───────── Rendu ───────── */

function ligneFichier(f) {
  const meta = [f.titre && f.nom, f.genre, taille(f.taille),
                f.maj && `mis à jour le ${dateCourte(f.maj)}`].filter(Boolean).join(", ");
  return `<li>
    <a href="${f.url}" download>${surligner(f.titre || f.nom)}</a>
    ${f.enseignant ? '<span class="badge">Version enseignant</span>' : ""}
    <span class="meta">${surligner(meta)}</span>
  </li>`;
}

function lignePaquet(p) {
  const meta = [pluriel(p.nb, "fichier", "fichiers"), taille(p.taille)].filter(Boolean).join(", ");
  return `<li><a href="${p.url}" download>Dossier ${surligner(p.nom)} (.zip)</a>
    <span class="meta">${esc(meta)}</span></li>`;
}

function blocGroupe(g) {
  if (g.zip) return `<ul class="fichiers">${lignePaquet(g)}</ul>`;
  return `<div class="groupe"><h5>${surligner(g.nom)}</h5>
    <ul class="fichiers">${g.fichiers.map(ligneFichier).join("")}${g.dossiers.map(lignePaquet).join("")}</ul></div>`;
}

/* Contenu d'une section ou d'une période : fichiers, dossiers zippés, puis groupes (TP1, TP2…) */
function contenu(b) {
  const zips = b.groupes.filter((g) => g.zip);
  const groupes = b.groupes.filter((g) => !g.zip);
  const directs = [...b.fichiers.map(ligneFichier), ...zips.map(lignePaquet)].join("");
  return (directs ? `<ul class="fichiers">${directs}</ul>` : "") + groupes.map(blocGroupe).join("");
}

function blocSection(s) {
  const abrev = s.court && s.court !== s.nom ? ` <span class="abrev">(${esc(s.court)})</span>` : "";
  const archives = s.archives.map((a) => `
    <details class="anciennes${a.recente ? " recente" : ""}"${a.recente ? " open" : ""}>
      <summary>${a.recente ? "Dernière version, années" : "Versions"} ${esc(a.periode)}
        (${pluriel(a.nb, "fichier", "fichiers")})</summary>
      <div class="archive-corps">${contenu(a)}</div>
    </details>`).join("");
  return `<section class="section">
    <h4>${esc(s.nom)}${abrev}</h4>
    ${contenu(s)}
    ${archives}
  </section>`;
}

function blocModule(m, ouvert) {
  const resume = [m.sections.map((s) => s.court).join(", "),
                  m.maj && `modifié le ${dateCourte(m.maj)}`].filter(Boolean).join(" ; ");
  const zip = m.zip && m.zip.taille
    ? `<a class="bouton" href="${m.zip.url}" download>Tout télécharger <span class="poids">(.zip, ${taille(m.zip.taille)})</span></a>`
    : "";
  const depot = m.depot ? `<a href="${m.depot}">Voir le dossier sur GitHub</a>` : "";
  return `<details class="module" id="${m.id}"${ouvert ? " open" : ""}>
    <summary>
      <span class="intitule">${m.code ? `<span class="code">${surligner(m.code)}</span>` : ""}${surligner(m.titre)}</span>
      <span class="resume">${esc(resume)}</span>
    </summary>
    <div class="module-corps">
      ${m.description ? `<p>${surligner(m.description)}</p>` : ""}
      <div class="actions">${zip}${depot}
        <button type="button" class="copier" data-id="${m.id}">Copier le lien vers ce module</button>
      </div>
      ${m.sections.map(blocSection).join("")}
    </div>
  </details>`;
}

/* ───────── Recherche ───────── */

function texteModule(m, c, n) {
  const noms = [];
  const bloc = (b) => {
    b.fichiers.forEach((f) => noms.push(f.nom, f.titre));
    b.groupes.forEach((g) => {
      noms.push(g.nom);
      (g.fichiers || []).forEach((f) => noms.push(f.nom, f.titre));
      (g.dossiers || []).forEach((d) => noms.push(d.nom));
    });
  };
  for (const s of m.sections) {
    noms.push(s.nom, s.court);
    bloc(s);
    s.archives.forEach((a) => { noms.push(a.periode); bloc(a); });
  }
  return sansAccents([m.code, m.titre, m.description, ...(m.mots_cles || []), c.nom, n.nom, ...noms].join(" "));
}

function correspond(m, c, n) {
  if (etat.composante && c.id !== etat.composante) return false;
  const mots = sansAccents(etat.q).split(/\s+/).filter(Boolean);
  if (!mots.length) return true;
  m._texte ??= texteModule(m, c, n);
  return mots.every((mot) => m._texte.includes(mot));
}

function afficher() {
  const D = etat.donnees;
  const racine = $("#catalogue");
  let total = 0;
  const resultats = [];
  for (const c of D.composantes) {
    const niveaux = [];
    for (const n of c.niveaux) {
      const mods = n.modules.filter((m) => correspond(m, c, n));
      if (mods.length) niveaux.push({ n, mods });
      total += mods.length;
    }
    if (niveaux.length) resultats.push({ c, niveaux });
  }

  const recherche = etat.q.trim();
  const ouvrir = recherche && total <= 3;   // peu de résultats : on les déplie
  racine.innerHTML = resultats.map(({ c, niveaux }) => `
    <section class="composante" aria-labelledby="c-${c.id}">
      <h2 id="c-${c.id}">${esc(c.nom)}</h2>
      <div class="composante-corps">
        ${niveaux.map(({ n, mods }) => `
          <div class="niveau">
            <h3>${esc(n.nom)}</h3>
            ${mods.map((m) => blocModule(m, ouvrir)).join("")}
          </div>`).join("")}
      </div>
    </section>`).join("");

  if (!D.composantes.length) {
    racine.innerHTML = `<p class="vide">Aucun support n'est encore publié. Revenez bientôt.</p>`;
  } else if (!total) {
    racine.innerHTML = `<div class="vide">
      <p>Aucun module ne correspond à « ${esc(recherche)} »${etat.composante ? " dans cette composante" : ""}.
      Essayez un code de module (R3.07), un thème (SQL) ou un type de support (TP).</p>
      <p><button type="button" id="effacer">Effacer la recherche et les filtres</button></p></div>`;
    $("#effacer").addEventListener("click", reinitialiser);
  }

  const tous = D.composantes.reduce((a, c) => a + c.niveaux.reduce((b, n) => b + n.modules.length, 0), 0);
  $("#bilan").textContent = recherche || etat.composante
    ? (total ? `${pluriel(total, "module correspond", "modules correspondent")} sur ${tous}.` : "")
    : `${pluriel(tous, "module", "modules")}, ${pluriel(D.nbDocuments, "document", "documents")} à jour.`;
}

function reinitialiser() {
  etat.q = ""; etat.composante = "";
  $("#q").value = "";
  majFiltres();
  afficher();
  $("#q").focus();
}

function majFiltres() {
  for (const b of $("#filtres").querySelectorAll("button")) {
    b.setAttribute("aria-pressed", String(b.dataset.c === etat.composante));
  }
}

/* ───────── Liens profonds : …/#iut-but-2-r3-07-bases-de-donnees ───────── */

function ouvrirAncre() {
  const id = decodeURIComponent(location.hash.slice(1));
  if (!id) return;
  let el = document.getElementById(id);
  if (!el && (etat.q || etat.composante)) { etat.q = ""; etat.composante = ""; $("#q").value = ""; majFiltres(); afficher(); el = document.getElementById(id); }
  if (el && el.tagName === "DETAILS") {
    el.open = true;
    el.scrollIntoView({ block: "start" });
    el.querySelector("summary").focus({ preventScroll: true });
  }
}

/* ───────── Démarrage ───────── */

async function demarrer() {
  let D = window.CATALOGUE;
  try {
    if (!D) {
      const r = await fetch("catalogue.json", { cache: "no-cache" });
      if (!r.ok) throw new Error(r.status);
      D = await r.json();
    }
  } catch (e) {
    $("#catalogue").innerHTML = `<p class="erreur">Le catalogue n'a pas pu être chargé (${esc(e.message)}).
      Rechargez la page ; si le problème persiste, les supports restent accessibles sur
      <a href="https://github.com">le dépôt GitHub</a>.</p>`;
    return;
  }
  D.nbDocuments = D.composantes.reduce((a, c) => a + c.niveaux.reduce((b, n) =>
    b + n.modules.reduce((x, m) => x + (m.nb || 0), 0), 0), 0);
  etat.donnees = D;

  $("#signature").innerHTML = `<strong>${esc(D.auteur)}</strong>, ${esc(D.affiliation)}`;
  const code = D.licence_code ? `, code sous licence <a href="LICENSE-CODE.txt">${esc(D.licence_code.nom)}</a>` : "";
  $("#licence").innerHTML = `Supports sous licence <a href="${esc(D.licence.url)}" rel="license">${esc(D.licence.nom)}</a>${code}. Réutilisation libre, en citant l'auteur.`;

  const filtres = $("#filtres");
  if (D.composantes.length > 1) {
    filtres.innerHTML = `<button type="button" data-c="">Toutes</button>` +
      D.composantes.map((c) => `<button type="button" data-c="${c.id}">${esc(c.nom)}</button>`).join("");
    filtres.addEventListener("click", (e) => {
      const b = e.target.closest("button");
      if (!b) return;
      etat.composante = b.dataset.c;
      majFiltres();
      afficher();
    });
    majFiltres();
  }

  let minuterie;
  $("#q").addEventListener("input", (e) => {
    clearTimeout(minuterie);
    minuterie = setTimeout(() => { etat.q = e.target.value; afficher(); }, 120);
  });
  document.addEventListener("keydown", (e) => {
    if (e.key === "/" && !/^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName)) {
      e.preventDefault(); $("#q").focus();
    }
    if (e.key === "Escape" && document.activeElement === $("#q") && $("#q").value) reinitialiser();
  });

  const catalogue = $("#catalogue");
  catalogue.addEventListener("toggle", (e) => {
    if (e.target.classList?.contains("module") && e.target.open) {
      history.replaceState(null, "", "#" + e.target.id);
    }
  }, true);
  catalogue.addEventListener("click", async (e) => {
    const b = e.target.closest(".copier");
    if (!b) return;
    const url = location.href.split("#")[0] + "#" + b.dataset.id;
    try { await navigator.clipboard.writeText(url); b.textContent = "Lien copié"; }
    catch { b.textContent = url; }
    setTimeout(() => { b.textContent = "Copier le lien vers ce module"; }, 2500);
  });

  const lien = D.depot ? `<a href="${esc(D.depot)}">dépôt GitHub</a>` : "dépôt GitHub";
  $("#pied").innerHTML = `<div>
    <p>Tous ces supports sont aussi disponibles dans le ${lien}, avec leur historique de versions.
      Une erreur, une suggestion ? ${D.depot ? `<a href="${esc(D.depot)}/issues">Ouvrez une issue</a>` : "Ouvrez une issue"}${D.contact ? ` ou <a href="${esc(D.contact)}">écrivez-moi</a>` : ""}.</p>
    <p>Catalogue généré le ${dateCourte(D.genere)}.</p></div>`;

  afficher();
  ouvrirAncre();
  window.addEventListener("hashchange", ouvrirAncre);
}

demarrer();
