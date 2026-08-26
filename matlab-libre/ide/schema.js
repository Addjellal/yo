/* schema.js — l'éditeur de schémas-blocs.

   On pose des blocs sur une toile SVG, on tire un fil d'une sortie vers une
   entrée, on règle les paramètres, et l'atelier écrit le modèle en appels
   new_system / add_block / add_line — le même modèle que celui qu'on
   écrirait à la main. « Simuler » exécute sim() dans l'interpréteur et
   ramène la courbe.

   Le tri des entrées suit l'ordre de connexion : c'est ce que fait add_line
   avec son numéro d'entrée, et c'est ce qui compte pour un bloc « sum »
   dont les signes sont ordonnés. */
'use strict';

const Schema = {
  blocs: [],
  liens: [],
  choisi: null,
  compteur: 0,
  lienEnCours: null,
};

const CATALOGUE = [
  { type: 'constant',    titre: 'Constante',       entrees: 0, parametres: { Value: 1 } },
  { type: 'step',        titre: 'Échelon',         entrees: 0, parametres: { Time: 1, Before: 0, After: 1 } },
  { type: 'ramp',        titre: 'Rampe',           entrees: 0, parametres: { Slope: 1 } },
  { type: 'sine',        titre: 'Sinusoïde',       entrees: 0, parametres: { Amplitude: 1, Frequency: 1, Phase: 0 } },
  { type: 'gain',        titre: 'Gain',            entrees: 1, parametres: { Gain: 2 } },
  { type: 'sum',         titre: 'Somme',           entrees: 2, parametres: { Signs: '+-' } },
  { type: 'product',     titre: 'Produit',         entrees: 2, parametres: {} },
  { type: 'integrator',  titre: 'Intégrateur',     entrees: 1, parametres: { InitialCondition: 0 } },
  { type: 'derivative',  titre: 'Dérivée',         entrees: 1, parametres: {} },
  { type: 'transferfcn', titre: 'Fonction de transfert', entrees: 1,
    parametres: { Numerator: '1', Denominator: '[1 1]' } },
  { type: 'statespace',  titre: 'Espace d’état', entrees: 1,
    parametres: { A: '[-1]', B: '[1]', C: '[1]', D: '[0]', X0: '[0]' } },
  { type: 'saturation',  titre: 'Saturation',      entrees: 1, parametres: { UpperLimit: 1, LowerLimit: -1 } },
  { type: 'delay',       titre: 'Retard',          entrees: 1, parametres: { InitialCondition: 0 } },
  { type: 'relay',       titre: 'Relais',          entrees: 1,
    parametres: { OnSwitch: 0.5, OffSwitch: -0.5, OnOutput: 1, OffOutput: -1 } },
  { type: 'abs',         titre: 'Valeur absolue',  entrees: 1, parametres: {} },
  { type: 'math',        titre: 'Fonction',        entrees: 1, parametres: { Operator: 'square' } },
  { type: 'scope',       titre: 'Oscilloscope',    entrees: 1, parametres: {} },
];

const LARGEUR_BLOC = 110;
const HAUTEUR_BLOC = 52;

function elementSchema(id) { return document.getElementById(id); }

function modeleDe(type) { return CATALOGUE.find((m) => m.type === type); }

function ajouterBloc(type, x, y) {
  const modele = modeleDe(type);
  if (!modele) return;
  Schema.compteur += 1;
  const bloc = {
    id: Schema.compteur,
    type: type,
    nom: type + Schema.compteur,
    x: Math.max(10, Math.round(x - LARGEUR_BLOC / 2)),
    y: Math.max(10, Math.round(y - HAUTEUR_BLOC / 2)),
    parametres: Object.assign({}, modele.parametres),
  };
  Schema.blocs.push(bloc);
  dessinerSchema();
  choisirBloc(bloc);
}

function nombreEntrees(bloc) {
  const modele = modeleDe(bloc.type);
  if (!modele) return 1;
  if (bloc.type === 'sum') return String(bloc.parametres.Signs || '+-').length;
  return modele.entrees;
}

function positionSortie(bloc) {
  return { x: bloc.x + LARGEUR_BLOC, y: bloc.y + HAUTEUR_BLOC / 2 };
}

function positionEntree(bloc, indice) {
  const total = Math.max(1, nombreEntrees(bloc));
  return { x: bloc.x, y: bloc.y + (HAUTEUR_BLOC * (indice + 1)) / (total + 1) };
}

function svgElement(nom, attributs) {
  const noeud = document.createElementNS('http://www.w3.org/2000/svg', nom);
  Object.keys(attributs || {}).forEach((cle) => noeud.setAttribute(cle, attributs[cle]));
  return noeud;
}

function dessinerSchema() {
  const toile = elementSchema('toileSchema');
  toile.innerHTML = '';
  const defs = svgElement('defs', {});
  const marqueur = svgElement('marker', {
    id: 'fleche', viewBox: '0 0 10 10', refX: '9', refY: '5',
    markerWidth: '6', markerHeight: '6', orient: 'auto-start-reverse',
  });
  marqueur.appendChild(svgElement('path', { d: 'M 0 0 L 10 5 L 0 10 z', fill: '#4f9cf9' }));
  defs.appendChild(marqueur);
  toile.appendChild(defs);

  Schema.liens.forEach((lien, indice) => {
    const source = Schema.blocs.find((b) => b.id === lien.source);
    const cible = Schema.blocs.find((b) => b.id === lien.cible);
    if (!source || !cible) return;
    const a = positionSortie(source);
    const b = positionEntree(cible, lien.entree - 1);
    const milieu = (a.x + b.x) / 2;
    const trace = svgElement('path', {
      class: 'lien',
      d: 'M ' + a.x + ' ' + a.y + ' C ' + milieu + ' ' + a.y + ', ' + milieu + ' ' + b.y +
         ', ' + b.x + ' ' + b.y,
    });
    trace.style.cursor = 'pointer';
    trace.onclick = () => { Schema.liens.splice(indice, 1); dessinerSchema(); };
    toile.appendChild(trace);
  });

  if (Schema.lienEnCours) {
    toile.appendChild(svgElement('path', {
      class: 'lien provisoire',
      d: 'M ' + Schema.lienEnCours.x0 + ' ' + Schema.lienEnCours.y0 + ' L ' +
         Schema.lienEnCours.x1 + ' ' + Schema.lienEnCours.y1,
    }));
  }

  Schema.blocs.forEach((bloc) => {
    const groupe = svgElement('g', {
      class: 'bloc' + (bloc === Schema.choisi ? ' choisi' : ''),
      transform: 'translate(' + bloc.x + ',' + bloc.y + ')',
    });
    groupe.appendChild(svgElement('rect', {
      width: LARGEUR_BLOC, height: HAUTEUR_BLOC, rx: 4, ry: 4,
    }));
    const titre = svgElement('text', { x: LARGEUR_BLOC / 2, y: 20 });
    titre.textContent = modeleDe(bloc.type).titre;
    groupe.appendChild(titre);
    const sousTitre = svgElement('text', { x: LARGEUR_BLOC / 2, y: 36 });
    sousTitre.textContent = bloc.nom;
    sousTitre.setAttribute('opacity', '0.6');
    groupe.appendChild(sousTitre);
    groupe.onmousedown = (e) => commencerDeplacementBloc(e, bloc);
    groupe.onclick = (e) => { e.stopPropagation(); choisirBloc(bloc); };
    toile.appendChild(groupe);

    if (bloc.type !== 'scope') {
      const sortie = positionSortie(bloc);
      const port = svgElement('circle', { class: 'port', cx: sortie.x, cy: sortie.y, r: 5 });
      port.onmousedown = (e) => commencerLien(e, bloc);
      toile.appendChild(port);
    }
    for (let k = 0; k < nombreEntrees(bloc); k++) {
      const entree = positionEntree(bloc, k);
      const port = svgElement('circle',
        { class: 'port entree', cx: entree.x, cy: entree.y, r: 5 });
      port.onmouseup = () => terminerLien(bloc, k + 1);
      toile.appendChild(port);
    }
  });
}

function commencerDeplacementBloc(evenement, bloc) {
  if (evenement.target.classList.contains('port')) return;
  evenement.preventDefault();
  choisirBloc(bloc);
  const cadre = elementSchema('toileSchema').getBoundingClientRect();
  const decalage = { x: evenement.clientX - cadre.left - bloc.x,
                     y: evenement.clientY - cadre.top - bloc.y };
  function bouger(e) {
    bloc.x = Math.max(0, e.clientX - cadre.left - decalage.x);
    bloc.y = Math.max(0, e.clientY - cadre.top - decalage.y);
    dessinerSchema();
  }
  function relacher() {
    document.removeEventListener('mousemove', bouger);
    document.removeEventListener('mouseup', relacher);
  }
  document.addEventListener('mousemove', bouger);
  document.addEventListener('mouseup', relacher);
}

function commencerLien(evenement, bloc) {
  evenement.preventDefault();
  evenement.stopPropagation();
  const cadre = elementSchema('toileSchema').getBoundingClientRect();
  const depart = positionSortie(bloc);
  Schema.lienEnCours = { source: bloc.id, x0: depart.x, y0: depart.y, x1: depart.x, y1: depart.y };
  function bouger(e) {
    Schema.lienEnCours.x1 = e.clientX - cadre.left;
    Schema.lienEnCours.y1 = e.clientY - cadre.top;
    dessinerSchema();
  }
  function relacher() {
    document.removeEventListener('mousemove', bouger);
    document.removeEventListener('mouseup', relacher);
    setTimeout(() => { Schema.lienEnCours = null; dessinerSchema(); }, 0);
  }
  document.addEventListener('mousemove', bouger);
  document.addEventListener('mouseup', relacher);
}

function terminerLien(bloc, entree) {
  if (!Schema.lienEnCours) return;
  if (Schema.lienEnCours.source === bloc.id) return;
  Schema.liens = Schema.liens.filter((l) => !(l.cible === bloc.id && l.entree === entree));
  Schema.liens.push({ source: Schema.lienEnCours.source, cible: bloc.id, entree: entree });
  Schema.lienEnCours = null;
  dessinerSchema();
}

function choisirBloc(bloc) {
  Schema.choisi = bloc;
  dessinerSchema();
  afficherParametres();
}

function afficherParametres() {
  const cadre = elementSchema('proprietesBloc');
  const bloc = Schema.choisi;
  if (!bloc) { cadre.innerHTML = '<p>Choisissez un bloc.</p>'; return; }
  let html = '<div class="champProp"><label>Nom</label>' +
    '<input data-param="__nom" value="' + bloc.nom + '"></div>';
  Object.keys(bloc.parametres).forEach((cle) => {
    html += '<div class="champProp"><label>' + cle + '</label>' +
      '<input data-param="' + cle + '" value="' +
      String(bloc.parametres[cle]).replace(/"/g, '&quot;') + '"></div>';
  });
  html += '<button class="boutonDanger" id="btnSupprimerBloc">Supprimer</button>';
  cadre.innerHTML = html;
  cadre.querySelectorAll('[data-param]').forEach((entree) => {
    entree.oninput = () => {
      if (entree.dataset.param === '__nom') bloc.nom = entree.value;
      else bloc.parametres[entree.dataset.param] = entree.value;
      dessinerSchema();
    };
  });
  document.getElementById('btnSupprimerBloc').onclick = () => {
    Schema.liens = Schema.liens.filter((l) => l.source !== bloc.id && l.cible !== bloc.id);
    Schema.blocs = Schema.blocs.filter((b) => b !== bloc);
    Schema.choisi = null;
    dessinerSchema();
    afficherParametres();
  };
}

/* -------------------------------------------------------- code du modèle */

function valeurMatlab(valeur) {
  const texte = String(valeur).trim();
  if (texte === '') return "''";
  // Un nombre ou une expression entre crochets part tel quel ; le reste est
  // du texte, et se cite.
  if (/^-?[0-9.]+([eE][-+]?[0-9]+)?$/.test(texte)) return texte;
  if (/^\[.*\]$/.test(texte)) return texte;
  return "'" + texte.replace(/'/g, "''") + "'";
}

function produireCodeModele() {
  const nom = elementSchema('nomModele').value || 'monModele';
  const lignes = [];
  lignes.push('function resultat = ' + nom + '(tFinal, pas)');
  lignes.push('%' + nom.toUpperCase() + ' Modèle construit avec l’éditeur de schémas.');
  lignes.push('    if nargin < 1, tFinal = ' + (elementSchema('finSimulation').value || 10) + '; end');
  lignes.push('    if nargin < 2, pas = ' + (elementSchema('pasSimulation').value || 0.01) + '; end');
  lignes.push('    modele = new_system(' + valeurMatlab(nom) + ');');
  Schema.blocs.forEach((bloc) => {
    let appel = "    modele = add_block(modele, '" + bloc.type + "', '" + bloc.nom + "'";
    Object.keys(bloc.parametres).forEach((cle) => {
      appel += ", '" + cle + "', " + valeurMatlab(bloc.parametres[cle]);
    });
    appel += ');';
    lignes.push(appel);
  });
  Schema.liens.forEach((lien) => {
    const source = Schema.blocs.find((b) => b.id === lien.source);
    const cible = Schema.blocs.find((b) => b.id === lien.cible);
    if (!source || !cible) return;
    lignes.push("    modele = add_line(modele, '" + source.nom + "', '" + cible.nom + "', " +
      lien.entree + ');');
  });
  lignes.push('    resultat = sim(modele, tFinal, pas);');
  lignes.push('end');
  return lignes.join('\n') + '\n';
}

async function simulerModele() {
  if (!Schema.blocs.length) {
    ecrireConsole('Le schéma est vide.\n', true);
    return;
  }
  const nom = elementSchema('nomModele').value || 'monModele';
  const code = produireCodeModele();
  elementSchema('codeModele').textContent = code;
  const chemin = (Atelier.dossier || '.') + '/' + nom + '.m';
  await poster('/api/fichier', { chemin: chemin, contenu: code });
  const tFinal = elementSchema('finSimulation').value || 10;
  const pas = elementSchema('pasSimulation').value || 0.01;
  // On trace tous les signaux, puis on récupère la figure en SVG.
  const commande = "rehash; resultatSchema = " + nom + "(" + tFinal + ", " + pas + "); " +
    "figure(); simplot(resultatSchema); title('" + nom + "');";
  executer(commande);
  setTimeout(async () => {
    const svg = await fetch('/api/figure').then((r) => r.text());
    elementSchema('resultatSimulation').innerHTML = svg;
  }, 700);
}

function installerSchema() {
  const palette = elementSchema('paletteBlocs');
  if (!palette) return;
  CATALOGUE.forEach((modele) => {
    const li = document.createElement('li');
    li.textContent = modele.titre;
    li.draggable = true;
    li.dataset.type = modele.type;
    li.addEventListener('dragstart', (e) => e.dataTransfer.setData('text/plain', modele.type));
    li.addEventListener('dblclick', () => ajouterBloc(modele.type, 90, 60));
    palette.appendChild(li);
  });

  const toile = elementSchema('toileSchema');
  toile.addEventListener('dragover', (e) => e.preventDefault());
  toile.addEventListener('drop', (e) => {
    e.preventDefault();
    const cadre = toile.getBoundingClientRect();
    ajouterBloc(e.dataTransfer.getData('text/plain'), e.clientX - cadre.left, e.clientY - cadre.top);
  });
  toile.addEventListener('click', () => { Schema.choisi = null; dessinerSchema(); afficherParametres(); });

  elementSchema('btnSimuler').onclick = simulerModele;
  elementSchema('btnModeleCode').onclick = () => {
    elementSchema('codeModele').textContent = produireCodeModele();
  };
  elementSchema('btnModeleEnregistrer').onclick = async () => {
    const nom = elementSchema('nomModele').value || 'monModele';
    const code = produireCodeModele();
    elementSchema('codeModele').textContent = code;
    const chemin = (Atelier.dossier || '.') + '/' + nom + '.m';
    await poster('/api/fichier', { chemin: chemin, contenu: code });
    ecrireConsole('Modèle enregistré : ' + chemin + '\n');
    listerDossier(Atelier.dossier);
  };
  elementSchema('btnModeleEffacer').onclick = () => {
    Schema.blocs = [];
    Schema.liens = [];
    Schema.choisi = null;
    dessinerSchema();
    afficherParametres();
    elementSchema('codeModele').textContent = '';
    elementSchema('resultatSimulation').innerHTML = '';
  };
  dessinerSchema();
}

document.addEventListener('DOMContentLoaded', installerSchema);
