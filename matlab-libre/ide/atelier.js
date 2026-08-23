/* atelier.js — le cœur de l'interface : éditeur, console, explorateur de
   variables, débogueur, profileur.

   Tout passe par l'API HTTP de l'atelier. L'interface interroge /api/etat
   quatre fois par seconde : c'est assez pour suivre une exécution, assez peu
   pour ne rien coûter. */
'use strict';

const Atelier = {
  fichier: null,
  pointsArret: {},          // fichier -> Set de lignes
  derniereSequence: -1,
  historique: [],
  positionHistorique: 0,
  fonctions: [],
};

/* ------------------------------------------------------------------ outils */

async function appelJson(chemin, options) {
  const reponse = await fetch(chemin, options);
  const type = reponse.headers.get('content-type') || '';
  if (type.indexOf('json') >= 0) return reponse.json();
  return reponse.text();
}

function poster(chemin, objet) {
  return appelJson(chemin, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(objet),
  });
}

function element(id) { return document.getElementById(id); }

function echapperHtml(texte) {
  return texte.replace(/[&<>]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]));
}

/* ------------------------------------------------------------- coloration */

const MOTS_CLES = new Set([
  'if', 'elseif', 'else', 'end', 'for', 'parfor', 'while', 'do', 'until',
  'switch', 'case', 'otherwise', 'break', 'continue', 'return', 'function',
  'classdef', 'properties', 'methods', 'events', 'enumeration', 'arguments',
  'try', 'catch', 'global', 'persistent', 'spmd', 'import',
]);

/* Colore une ligne de MATLAB. L'apostrophe est ambiguë : après un nom, un
   nombre ou une parenthèse fermante, c'est une transposition ; sinon c'est
   le début d'une chaîne. C'est la règle du langage, et elle suffit ici. */
function colorerLigne(ligne) {
  let sortie = '';
  let i = 0;
  let precedent = '';
  while (i < ligne.length) {
    const c = ligne[i];
    if (c === '%' || (c === '#' && ligne[i + 1] === '#')) {
      sortie += '<span class="commentaire">' + echapperHtml(ligne.slice(i)) + '</span>';
      break;
    }
    if (c === '"') {
      let j = i + 1;
      while (j < ligne.length && ligne[j] !== '"') j++;
      sortie += '<span class="chaine">' + echapperHtml(ligne.slice(i, j + 1)) + '</span>';
      i = j + 1;
      precedent = 'valeur';
      continue;
    }
    if (c === "'" && precedent !== 'valeur') {
      let j = i + 1;
      while (j < ligne.length) {
        if (ligne[j] === "'" && ligne[j + 1] === "'") { j += 2; continue; }
        if (ligne[j] === "'") break;
        j++;
      }
      sortie += '<span class="chaine">' + echapperHtml(ligne.slice(i, j + 1)) + '</span>';
      i = j + 1;
      precedent = 'valeur';
      continue;
    }
    if (/[A-Za-z_]/.test(c)) {
      let j = i;
      while (j < ligne.length && /[A-Za-z0-9_]/.test(ligne[j])) j++;
      const mot = ligne.slice(i, j);
      if (MOTS_CLES.has(mot)) sortie += '<span class="mot">' + mot + '</span>';
      else if (ligne[j] === '(') sortie += '<span class="fonction">' + mot + '</span>';
      else sortie += echapperHtml(mot);
      i = j;
      precedent = 'valeur';
      continue;
    }
    if (/[0-9]/.test(c)) {
      let j = i;
      while (j < ligne.length && /[0-9.eE]/.test(ligne[j])) j++;
      sortie += '<span class="nombre">' + ligne.slice(i, j) + '</span>';
      i = j;
      precedent = 'valeur';
      continue;
    }
    sortie += echapperHtml(c);
    precedent = (c === ')' || c === ']' || c === '}') ? 'valeur' : '';
    i++;
  }
  return sortie;
}

function rafraichirColoration() {
  const texte = element('editeur').value;
  const lignes = texte.split('\n');
  element('coloration').innerHTML = lignes.map(colorerLigne).join('\n') + '\n';
  const editeur = element('editeur');
  editeur.style.height = Math.max(lignes.length * 19.5 + 40, 200) + 'px';
  rafraichirGouttiere(lignes.length);
}

function rafraichirGouttiere(nombreLignes) {
  const gouttiere = element('gouttiere');
  const arrets = Atelier.pointsArret[Atelier.fichier] || new Set();
  let html = '';
  for (let k = 1; k <= nombreLignes; k++) {
    const marque = arrets.has(k) ? ' arret' : '';
    html += '<div class="ligne' + marque + '" data-ligne="' + k + '">' + k + '</div>';
  }
  gouttiere.innerHTML = html;
}

/* --------------------------------------------------------------- fichiers */

async function listerDossier(chemin) {
  const donnees = await appelJson('/api/dossier?chemin=' + encodeURIComponent(chemin || '.'));
  element('cheminCourant').textContent = donnees.dossier;
  Atelier.dossier = donnees.dossier;
  const liste = element('listeFichiers');
  liste.innerHTML = '';
  const parent = document.createElement('li');
  parent.textContent = '..';
  parent.className = 'dossier';
  parent.onclick = () => listerDossier(donnees.dossier + '/..');
  liste.appendChild(parent);
  donnees.entrees.forEach((e) => {
    if (!e.dossier && !/\.(m|txt|csv|json|c|h)$/.test(e.nom)) return;
    const li = document.createElement('li');
    li.textContent = e.nom;
    if (e.dossier) li.className = 'dossier';
    li.onclick = () => {
      const complet = donnees.dossier + '/' + e.nom;
      if (e.dossier) listerDossier(complet);
      else ouvrirFichier(complet);
    };
    liste.appendChild(li);
  });
}

async function ouvrirFichier(chemin) {
  const donnees = await appelJson('/api/fichier?chemin=' + encodeURIComponent(chemin));
  if (donnees.erreur) { ecrireConsole('Erreur : ' + donnees.erreur + '\n', true); return; }
  Atelier.fichier = chemin;
  element('nomFichier').textContent = chemin;
  element('editeur').value = donnees.contenu;
  rafraichirColoration();
}

async function enregistrerFichier() {
  let chemin = Atelier.fichier;
  if (!chemin) {
    chemin = prompt('Nom du fichier', (Atelier.dossier || '.') + '/sans-titre.m');
    if (!chemin) return;
    Atelier.fichier = chemin;
    element('nomFichier').textContent = chemin;
  }
  await poster('/api/fichier', { chemin: chemin, contenu: element('editeur').value });
  ecrireConsole('Enregistré : ' + chemin + '\n');
  listerDossier(Atelier.dossier);
}

/* ---------------------------------------------------------------- console */

function ecrireConsole(texte, erreur) {
  const cadre = element('sortieConsole');
  const bloc = document.createElement('span');
  if (erreur) bloc.className = 'erreur';
  bloc.textContent = texte;
  cadre.appendChild(bloc);
  cadre.scrollTop = cadre.scrollHeight;
}

function executer(code) {
  if (!code.trim()) return;
  ecrireConsole('>> ' + code + '\n');
  Atelier.historique.push(code);
  Atelier.positionHistorique = Atelier.historique.length;
  poster('/api/executer', { code: code });
}

/* ------------------------------------------------------------------- état */

async function interrogerEtat() {
  let etat;
  try {
    etat = await appelJson('/api/etat');
  } catch (e) {
    return;
  }
  if (etat.sortie) {
    const lignes = etat.sortie.split('\n');
    lignes.forEach((l, i) => {
      const texte = i === lignes.length - 1 ? l : l + '\n';
      if (!texte) return;
      ecrireConsole(texte, /^Error:/.test(l));
    });
  }
  const indicateur = element('etatExecution');
  if (etat.arrete) {
    indicateur.textContent = 'arrêté ligne ' + etat.ligneArret;
    indicateur.className = 'etat arrete';
  } else if (etat.occupe) {
    indicateur.textContent = 'exécution…';
    indicateur.className = 'etat occupe';
  } else {
    indicateur.textContent = 'au repos';
    indicateur.className = 'etat';
  }
  ['btnContinuer', 'btnPas', 'btnEntrer', 'btnSortir', 'btnQuitterDebug'].forEach((id) => {
    element(id).disabled = !etat.arrete;
  });
  marquerLigneArret(etat.arrete ? etat.ligneArret : 0);
  rafraichirVariables(etat.variables);
  rafraichirChoixFigures(etat.figures);
}

function marquerLigneArret(ligne) {
  document.querySelectorAll('#gouttiere .ici').forEach((d) => d.classList.remove('ici'));
  if (!ligne) return;
  const cible = document.querySelector('#gouttiere div[data-ligne="' + ligne + '"]');
  if (cible) cible.classList.add('ici');
}

function rafraichirVariables(variables) {
  const corps = document.querySelector('#tableVariables tbody');
  const signature = JSON.stringify(variables);
  if (corps.dataset.signature === signature) return;
  corps.dataset.signature = signature;
  corps.innerHTML = '';
  variables.forEach((v) => {
    const tr = document.createElement('tr');
    tr.innerHTML = '<td>' + echapperHtml(v.nom) + '</td><td>' + echapperHtml(v.classe) +
      '</td><td>' + echapperHtml(v.taille) + '</td><td title="' +
      echapperHtml(v.valeur) + '">' + echapperHtml(v.valeur.split('\n')[0]) + '</td>';
    tr.onclick = () => executer(v.nom);
    corps.appendChild(tr);
  });
}

function rafraichirChoixFigures(figures) {
  const choix = element('choixFigure');
  const signature = JSON.stringify(figures);
  if (choix.dataset.signature === signature) return;
  choix.dataset.signature = signature;
  const avant = choix.value;
  choix.innerHTML = '';
  figures.forEach((n) => {
    const option = document.createElement('option');
    option.value = n;
    option.textContent = 'Figure ' + n;
    choix.appendChild(option);
  });
  if (avant) choix.value = avant;
}

/* ------------------------------------------------------------- débogueur */

function commandeDebogueur(action) {
  poster('/api/debogueur', { action: action });
}

async function basculerPointArret(ligne) {
  if (!Atelier.fichier) {
    ecrireConsole('Enregistrez le fichier avant d’y poser un point d’arrêt.\n', true);
    return;
  }
  const arrets = Atelier.pointsArret[Atelier.fichier] || new Set();
  const action = arrets.has(ligne) ? 'retirer' : 'poser';
  if (action === 'poser') arrets.add(ligne); else arrets.delete(ligne);
  Atelier.pointsArret[Atelier.fichier] = arrets;
  const liste = await poster('/api/pointsarret',
    { fichier: Atelier.fichier, ligne: ligne, action: action });
  rafraichirColoration();
  rafraichirListePointsArret(liste);
}

function rafraichirListePointsArret(liste) {
  const ul = element('listePointsArret');
  ul.innerHTML = '';
  (liste || []).forEach((p) => {
    const li = document.createElement('li');
    li.textContent = p.fichier + ' : ' + p.ligne;
    li.onclick = () => poster('/api/pointsarret',
      { fichier: p.fichier, ligne: p.ligne, action: 'retirer' }).then(rafraichirListePointsArret);
    ul.appendChild(li);
  });
}

/* -------------------------------------------------------------- profileur */

async function rafraichirProfil() {
  const liste = await appelJson('/api/profil');
  const corps = document.querySelector('#tableProfil tbody');
  corps.innerHTML = '';
  const maximum = liste.reduce((m, e) => Math.max(m, e.propre), 0) || 1;
  liste.forEach((e) => {
    const tr = document.createElement('tr');
    const largeur = Math.round((e.propre / maximum) * 100);
    tr.innerHTML = '<td>' + echapperHtml(e.nom) + '</td>' +
      '<td class="nombre">' + e.appels + '</td>' +
      '<td class="nombre">' + e.total.toFixed(6) + '</td>' +
      '<td class="nombre">' + e.propre.toFixed(6) + '</td>' +
      '<td><span class="barreProportion" style="width:' + largeur + '%"></span></td>';
    corps.appendChild(tr);
  });
}

/* --------------------------------------------------------------- figures */

async function afficherFigure() {
  const numero = element('choixFigure').value;
  if (!numero) { element('cadreFigure').innerHTML = '<p>Aucune figure.</p>'; return; }
  const svg = await fetch('/api/figure?numero=' + numero).then((r) => r.text());
  element('cadreFigure').innerHTML = svg;
}

function telechargerFigure() {
  const svg = element('cadreFigure').innerHTML;
  if (!svg) return;
  const lien = document.createElement('a');
  lien.href = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(svg);
  lien.download = 'figure' + element('choixFigure').value + '.svg';
  lien.click();
}

/* ------------------------------------------------------------ démarrage */

function changerVue(nom) {
  document.querySelectorAll('.onglet').forEach((b) => {
    b.classList.toggle('actif', b.dataset.vue === nom);
  });
  document.querySelectorAll('.vue').forEach((v) => {
    v.classList.toggle('active', v.id === 'vue-' + nom);
  });
  if (nom === 'figures') afficherFigure();
  if (nom === 'profil') rafraichirProfil();
}

function installer() {
  document.querySelectorAll('.onglet').forEach((b) => {
    b.onclick = () => changerVue(b.dataset.vue);
  });

  const editeur = element('editeur');
  editeur.addEventListener('input', rafraichirColoration);
  editeur.addEventListener('scroll', () => {
    element('coloration').scrollTop = editeur.scrollTop;
  });
  editeur.addEventListener('keydown', (e) => {
    if (e.key === 'Tab') {
      e.preventDefault();
      const debut = editeur.selectionStart;
      editeur.value = editeur.value.slice(0, debut) + '    ' + editeur.value.slice(editeur.selectionEnd);
      editeur.selectionStart = editeur.selectionEnd = debut + 4;
      rafraichirColoration();
    }
  });

  element('gouttiere').addEventListener('click', (e) => {
    const ligne = e.target.dataset.ligne;
    if (ligne) basculerPointArret(parseInt(ligne, 10));
  });

  element('btnNouveau').onclick = () => {
    Atelier.fichier = null;
    element('nomFichier').textContent = 'sans-titre.m';
    editeur.value = '';
    rafraichirColoration();
  };
  element('btnEnregistrer').onclick = enregistrerFichier;
  element('btnExecuter').onclick = async () => {
    if (Atelier.fichier) {
      await enregistrerFichier();
      executer("run('" + Atelier.fichier.replace(/'/g, "''") + "')");
    } else {
      executer(editeur.value);
    }
  };
  element('btnContinuer').onclick = () => commandeDebogueur('continuer');
  element('btnPas').onclick = () => commandeDebogueur('pas');
  element('btnEntrer').onclick = () => commandeDebogueur('entrer');
  element('btnSortir').onclick = () => commandeDebogueur('sortir');
  element('btnQuitterDebug').onclick = () => commandeDebogueur('quitter');

  const saisie = element('saisie');
  saisie.addEventListener('keydown', (e) => {
    if (e.key === 'Enter') {
      executer(saisie.value);
      saisie.value = '';
    } else if (e.key === 'ArrowUp') {
      if (Atelier.positionHistorique > 0) {
        Atelier.positionHistorique--;
        saisie.value = Atelier.historique[Atelier.positionHistorique] || '';
      }
      e.preventDefault();
    } else if (e.key === 'ArrowDown') {
      if (Atelier.positionHistorique < Atelier.historique.length - 1) {
        Atelier.positionHistorique++;
        saisie.value = Atelier.historique[Atelier.positionHistorique] || '';
      } else {
        Atelier.positionHistorique = Atelier.historique.length;
        saisie.value = '';
      }
      e.preventDefault();
    }
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'F5') { e.preventDefault(); element('btnExecuter').click(); }
    if (e.key === 'F10' && !element('btnPas').disabled) { e.preventDefault(); commandeDebogueur('pas'); }
    if (e.key === 'F11' && !element('btnEntrer').disabled) { e.preventDefault(); commandeDebogueur('entrer'); }
    if (e.key === 'F8' && !element('btnContinuer').disabled) { e.preventDefault(); commandeDebogueur('continuer'); }
    if (e.key === 's' && (e.ctrlKey || e.metaKey)) { e.preventDefault(); enregistrerFichier(); }
  });

  element('btnRafraichirFigure').onclick = afficherFigure;
  element('choixFigure').onchange = afficherFigure;
  element('btnTelechargerFigure').onclick = telechargerFigure;

  element('btnProfilOn').onclick = () => executer('profile on');
  element('btnProfilOff').onclick = () => { executer('profile off'); setTimeout(rafraichirProfil, 300); };
  element('btnProfilClear').onclick = () => { executer('profile clear'); setTimeout(rafraichirProfil, 300); };
  element('btnProfilRafraichir').onclick = rafraichirProfil;

  listerDossier('.');
  rafraichirColoration();
  appelJson('/api/fonctions').then((liste) => { Atelier.fonctions = liste; });
  setInterval(interrogerEtat, 250);
}

document.addEventListener('DOMContentLoaded', installer);

// L'objet est exposé pour les vérifications automatiques, qui doivent
// pouvoir déplacer le dossier de travail.
window.Atelier = Atelier;
