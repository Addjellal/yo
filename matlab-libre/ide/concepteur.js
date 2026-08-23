/* concepteur.js — le concepteur d'applications.

   On glisse des composants sur une toile, on règle leurs propriétés, et
   l'atelier écrit le fichier .m correspondant : une fonction qui construit
   la figure, pose les contrôles et déclare leurs rappels. Le code produit
   n'appelle que des fonctions du langage — uifigure, uibutton, uilabel… —
   et se relit sans l'atelier. */
'use strict';

const Concepteur = {
  composants: [],
  choisi: null,
  compteur: 0,
};

const MODELES_COMPOSANTS = {
  button:   { etiquette: 'Bouton',          largeur: 100, hauteur: 26, texte: 'Bouton' },
  label:    { etiquette: 'Étiquette',       largeur: 110, hauteur: 22, texte: 'Étiquette' },
  edit:     { etiquette: 'Champ de texte',  largeur: 140, hauteur: 24, texte: '' },
  numeric:  { etiquette: 'Champ numérique', largeur: 100, hauteur: 24, valeur: 0 },
  slider:   { etiquette: 'Curseur',         largeur: 150, hauteur: 30, minimum: 0, maximum: 100, valeur: 50 },
  checkbox: { etiquette: 'Case à cocher',   largeur: 130, hauteur: 22, texte: 'Option', valeur: 0 },
  dropdown: { etiquette: 'Liste',           largeur: 130, hauteur: 24, choix: 'un, deux, trois' },
  axes:     { etiquette: 'Axes',            largeur: 260, hauteur: 180 },
  table:    { etiquette: 'Table',           largeur: 240, hauteur: 140 },
  panel:    { etiquette: 'Panneau',         largeur: 200, hauteur: 140, texte: 'Panneau' },
};

function elementConcepteur(id) { return document.getElementById(id); }

function nomComposant(type) {
  Concepteur.compteur += 1;
  return type + Concepteur.compteur;
}

function ajouterComposant(type, x, y) {
  const modele = MODELES_COMPOSANTS[type];
  if (!modele) return;
  const composant = Object.assign({}, modele, {
    type: type,
    nom: nomComposant(type),
    x: Math.max(0, Math.round(x)),
    y: Math.max(0, Math.round(y)),
    rappel: '',
  });
  Concepteur.composants.push(composant);
  dessinerComposants();
  choisirComposant(composant);
}

function dessinerComposants() {
  const toile = elementConcepteur('toileApplication');
  toile.innerHTML = '';
  Concepteur.composants.forEach((c) => {
    const noeud = document.createElement('div');
    noeud.className = 'composant ' + c.type + (c === Concepteur.choisi ? ' choisi' : '');
    noeud.style.left = c.x + 'px';
    noeud.style.top = c.y + 'px';
    noeud.style.width = c.largeur + 'px';
    noeud.style.height = c.hauteur + 'px';
    noeud.textContent = c.texte !== undefined ? (c.texte || c.nom) : c.nom;
    noeud.onmousedown = (e) => commencerDeplacement(e, c, noeud);
    noeud.onclick = (e) => { e.stopPropagation(); choisirComposant(c); };
    toile.appendChild(noeud);
  });
}

function commencerDeplacement(evenement, composant, noeud) {
  evenement.preventDefault();
  choisirComposant(composant);
  const depart = { x: evenement.clientX, y: evenement.clientY, cx: composant.x, cy: composant.y };
  function bouger(e) {
    composant.x = Math.max(0, depart.cx + (e.clientX - depart.x));
    composant.y = Math.max(0, depart.cy + (e.clientY - depart.y));
    noeud.style.left = composant.x + 'px';
    noeud.style.top = composant.y + 'px';
  }
  function relacher() {
    document.removeEventListener('mousemove', bouger);
    document.removeEventListener('mouseup', relacher);
    afficherProprietes();
  }
  document.addEventListener('mousemove', bouger);
  document.addEventListener('mouseup', relacher);
}

function choisirComposant(composant) {
  Concepteur.choisi = composant;
  dessinerComposants();
  afficherProprietes();
}

function champTexte(cle, etiquette, valeur, type) {
  return '<div class="champProp"><label>' + etiquette + '</label>' +
    '<input data-cle="' + cle + '" type="' + (type || 'text') + '" value="' +
    String(valeur).replace(/"/g, '&quot;') + '"></div>';
}

function afficherProprietes() {
  const cadre = elementConcepteur('proprietesComposant');
  const c = Concepteur.choisi;
  if (!c) { cadre.innerHTML = '<p>Choisissez un composant.</p>'; return; }
  let html = champTexte('nom', 'Nom de la variable', c.nom);
  if (c.texte !== undefined) html += champTexte('texte', 'Texte', c.texte);
  html += champTexte('x', 'X', c.x, 'number');
  html += champTexte('y', 'Y', c.y, 'number');
  html += champTexte('largeur', 'Largeur', c.largeur, 'number');
  html += champTexte('hauteur', 'Hauteur', c.hauteur, 'number');
  if (c.minimum !== undefined) html += champTexte('minimum', 'Minimum', c.minimum, 'number');
  if (c.maximum !== undefined) html += champTexte('maximum', 'Maximum', c.maximum, 'number');
  if (c.valeur !== undefined) html += champTexte('valeur', 'Valeur', c.valeur);
  if (c.choix !== undefined) html += champTexte('choix', 'Choix (séparés par des virgules)', c.choix);
  if (c.type === 'button' || c.type === 'slider' || c.type === 'checkbox' ||
      c.type === 'dropdown' || c.type === 'edit') {
    html += '<div class="champProp"><label>Rappel (code MATLAB)</label>' +
      '<textarea data-cle="rappel" rows="3">' + (c.rappel || '') + '</textarea></div>';
  }
  html += '<button class="boutonDanger" id="btnSupprimerComposant">Supprimer</button>';
  cadre.innerHTML = html;
  cadre.querySelectorAll('[data-cle]').forEach((entree) => {
    entree.oninput = () => {
      const cle = entree.dataset.cle;
      const valeur = entree.type === 'number' ? parseFloat(entree.value) : entree.value;
      c[cle] = valeur;
      dessinerComposants();
    };
  });
  const bouton = document.getElementById('btnSupprimerComposant');
  if (bouton) bouton.onclick = () => {
    Concepteur.composants = Concepteur.composants.filter((x) => x !== c);
    Concepteur.choisi = null;
    dessinerComposants();
    afficherProprietes();
  };
}

/* ------------------------------------------------------- code produit */

function texteMatlab(valeur) {
  return "'" + String(valeur).replace(/'/g, "''") + "'";
}

function produireCodeApplication() {
  const nom = elementConcepteur('nomApplication').value || 'MonApplication';
  const composants = Concepteur.composants;
  let hauteurToile = 400;
  let largeurToile = 600;
  composants.forEach((c) => {
    largeurToile = Math.max(largeurToile, c.x + c.largeur + 20);
    hauteurToile = Math.max(hauteurToile, c.y + c.hauteur + 20);
  });
  const lignes = [];
  lignes.push('function ' + nom + '()');
  lignes.push('%' + nom.toUpperCase() + ' Application construite avec le concepteur MatLibre.');
  lignes.push('%   Les positions sont en pixels, mesurées depuis le coin bas-gauche,');
  lignes.push('%   comme le veut la propriété Position de MATLAB.');
  lignes.push('    app.Figure = uifigure(' + texteMatlab(nom) + ', [' +
    largeurToile + ' ' + hauteurToile + ']);');
  composants.forEach((c) => {
    // La toile de l'atelier compte du haut ; MATLAB compte du bas.
    const bas = hauteurToile - c.y - c.hauteur;
    const position = '[' + c.x + ' ' + bas + ' ' + c.largeur + ' ' + c.hauteur + ']';
    switch (c.type) {
      case 'button':
        lignes.push('    app.' + c.nom + ' = uibutton(app.Figure, ' + texteMatlab(c.texte) +
          ', ' + position + ');');
        break;
      case 'label':
        lignes.push('    app.' + c.nom + ' = uilabel(app.Figure, ' + texteMatlab(c.texte) +
          ', ' + position + ');');
        break;
      case 'edit':
        lignes.push('    app.' + c.nom + ' = uieditfield(app.Figure, ' + texteMatlab(c.texte) +
          ', ' + position + ');');
        break;
      case 'numeric':
        lignes.push('    app.' + c.nom + ' = uieditfield(app.Figure, ' +
          texteMatlab(String(c.valeur)) + ', ' + position + ', ' + texteMatlab('numeric') + ');');
        break;
      case 'slider':
        lignes.push('    app.' + c.nom + ' = uislider(app.Figure, [' + c.minimum + ' ' +
          c.maximum + '], ' + c.valeur + ', ' + position + ');');
        break;
      case 'checkbox':
        lignes.push('    app.' + c.nom + ' = uicheckbox(app.Figure, ' + texteMatlab(c.texte) +
          ', ' + (c.valeur ? 'true' : 'false') + ', ' + position + ');');
        break;
      case 'dropdown': {
        const items = String(c.choix).split(',').map((s) => texteMatlab(s.trim())).join(', ');
        lignes.push('    app.' + c.nom + ' = uidropdown(app.Figure, {' + items + '}, ' +
          position + ');');
        break;
      }
      case 'axes':
        lignes.push('    app.' + c.nom + ' = uiaxes(app.Figure, ' + position + ');');
        break;
      case 'table':
        lignes.push('    app.' + c.nom + ' = uitable(app.Figure, [], ' + position + ');');
        break;
      case 'panel':
        lignes.push('    app.' + c.nom + ' = uipanel(app.Figure, ' + texteMatlab(c.texte) +
          ', ' + position + ');');
        break;
      default:
        break;
    }
  });
  const avecRappel = composants.filter((c) => c.rappel && c.rappel.trim());
  avecRappel.forEach((c) => {
    lignes.push('    set(app.' + c.nom + ', ' + texteMatlab('Callback') + ', @(source, evenement) ' +
      nom + '_' + c.nom + '(app, source, evenement));');
  });
  lignes.push('    uiwait(app.Figure);');
  lignes.push('end');
  avecRappel.forEach((c) => {
    lignes.push('');
    lignes.push('function ' + nom + '_' + c.nom + '(app, source, evenement)');
    lignes.push('%   Rappel de ' + c.nom + '.');
    String(c.rappel).split('\n').forEach((l) => lignes.push('    ' + l));
    lignes.push('end');
  });
  return lignes.join('\n') + '\n';
}

function installerConcepteur() {
  const toile = elementConcepteur('toileApplication');
  if (!toile) return;

  document.querySelectorAll('#paletteComposants li').forEach((li) => {
    li.addEventListener('dragstart', (e) => {
      e.dataTransfer.setData('text/plain', li.dataset.type);
    });
    li.addEventListener('dblclick', () => ajouterComposant(li.dataset.type, 20, 20));
  });

  toile.addEventListener('dragover', (e) => e.preventDefault());
  toile.addEventListener('drop', (e) => {
    e.preventDefault();
    const type = e.dataTransfer.getData('text/plain');
    const cadre = toile.getBoundingClientRect();
    ajouterComposant(type, e.clientX - cadre.left, e.clientY - cadre.top);
  });
  toile.addEventListener('click', () => { Concepteur.choisi = null; dessinerComposants(); afficherProprietes(); });

  elementConcepteur('btnAppCode').onclick = () => {
    elementConcepteur('codeApplication').textContent = produireCodeApplication();
  };
  elementConcepteur('btnAppEnregistrer').onclick = async () => {
    const nom = elementConcepteur('nomApplication').value || 'MonApplication';
    const code = produireCodeApplication();
    elementConcepteur('codeApplication').textContent = code;
    const chemin = (Atelier.dossier || '.') + '/' + nom + '.m';
    await poster('/api/fichier', { chemin: chemin, contenu: code });
    ecrireConsole('Application enregistrée : ' + chemin + '\n');
    listerDossier(Atelier.dossier);
  };
  elementConcepteur('btnAppEffacer').onclick = () => {
    Concepteur.composants = [];
    Concepteur.choisi = null;
    dessinerComposants();
    afficherProprietes();
    elementConcepteur('codeApplication').textContent = '';
  };
}

document.addEventListener('DOMContentLoaded', installerConcepteur);

/* ------------------------------------------------ exécution de l'interface

   « Exécuter » lance le code produit dans l'interpréteur, puis dessine la
   fenêtre décrite par le registre des composants. Les clics repartent vers
   l'interpréteur, qui déclenche les rappels : c'est la même application que
   celle qu'on lancerait en ligne de commande. */

const Execution = { actif: false, minuteur: null, signature: '' };

function positionCss(composant, hauteurFenetre) {
  const p = composant.position || [];
  const x = p[0] || 0;
  const bas = p[1] || 0;
  const largeur = p[2] || 100;
  const hauteur = p[3] || 24;
  return { left: x + 'px', top: (hauteurFenetre - bas - hauteur) + 'px',
           width: largeur + 'px', height: hauteur + 'px' };
}

function envoyerEvenement(id, valeur, genre) {
  return poster('/api/ui/evenement', { id: id, valeur: valeur, genre: genre });
}

function dessinerInterfaceVivante(composants) {
  const toile = elementConcepteur('toileExecution');
  const fenetre = composants.find((c) => c.type === 'figure');
  const hauteurFenetre = fenetre && fenetre.position ? fenetre.position[3] : 400;
  const largeurFenetre = fenetre && fenetre.position ? fenetre.position[2] : 600;
  toile.style.width = largeurFenetre + 'px';
  toile.style.height = hauteurFenetre + 'px';
  toile.innerHTML = '';
  composants.forEach((c) => {
    if (c.type === 'figure' || !c.visible) return;
    const cadre = document.createElement('div');
    cadre.className = 'vivant';
    Object.assign(cadre.style, positionCss(c, hauteurFenetre));
    let controle = null;
    switch (c.type) {
      case 'button':
        controle = document.createElement('button');
        controle.textContent = c.texte;
        controle.style.width = '100%';
        controle.style.height = '100%';
        controle.disabled = !c.actif;
        controle.onclick = () => envoyerEvenement(c.id, '', 'aucun');
        break;
      case 'label':
        controle = document.createElement('span');
        controle.textContent = c.texte;
        break;
      case 'edit_text':
        controle = document.createElement('input');
        controle.value = c.valeur === null ? '' : String(c.valeur);
        controle.style.width = '100%';
        controle.onchange = () => envoyerEvenement(c.id, controle.value, 'texte');
        break;
      case 'edit_numeric':
        controle = document.createElement('input');
        controle.type = 'number';
        controle.value = c.valeur === null ? 0 : c.valeur;
        controle.style.width = '100%';
        controle.onchange = () => envoyerEvenement(c.id, controle.value, 'nombre');
        break;
      case 'slider':
        controle = document.createElement('input');
        controle.type = 'range';
        controle.min = c.minimum;
        controle.max = c.maximum;
        controle.step = (c.maximum - c.minimum) / 100 || 1;
        controle.value = c.valeur === null ? c.minimum : c.valeur;
        controle.style.width = '100%';
        controle.onchange = () => envoyerEvenement(c.id, controle.value, 'nombre');
        break;
      case 'checkbox': {
        controle = document.createElement('label');
        const case_ = document.createElement('input');
        case_.type = 'checkbox';
        case_.checked = c.valeur === true || c.valeur === 1;
        case_.onchange = () => envoyerEvenement(c.id, case_.checked ? 1 : 0, 'nombre');
        controle.appendChild(case_);
        controle.appendChild(document.createTextNode(' ' + c.texte));
        break;
      }
      case 'dropdown':
        controle = document.createElement('select');
        (c.items || []).forEach((item) => {
          const option = document.createElement('option');
          option.value = item;
          option.textContent = item;
          controle.appendChild(option);
        });
        if (c.valeur) controle.value = c.valeur;
        controle.style.width = '100%';
        controle.onchange = () => envoyerEvenement(c.id, controle.value, 'texte');
        break;
      case 'axes':
        controle = document.createElement('div');
        controle.className = 'zoneAxes';
        controle.style.width = '100%';
        controle.style.height = '100%';
        controle.dataset.axes = c.id;
        break;
      case 'panel':
        controle = document.createElement('div');
        controle.className = 'zonePanneau';
        controle.style.width = '100%';
        controle.style.height = '100%';
        controle.textContent = c.texte;
        break;
      case 'table': {
        controle = document.createElement('div');
        controle.style.width = '100%';
        controle.style.height = '100%';
        controle.style.overflow = 'auto';
        const table = document.createElement('table');
        table.innerHTML = '<tbody><tr><td>' +
          echapperHtml(String(c.valeur === null ? '' : c.valeur)) + '</td></tr></tbody>';
        controle.appendChild(table);
        break;
      }
      default:
        controle = document.createElement('span');
        controle.textContent = c.texte || c.type;
    }
    cadre.appendChild(controle);
    toile.appendChild(cadre);
  });
  // Les zones de tracé reçoivent la figure courante.
  const zones = toile.querySelectorAll('.zoneAxes');
  if (zones.length) {
    fetch('/api/figure').then((r) => r.text()).then((svg) => {
      zones.forEach((z) => {
        z.innerHTML = svg;
        const dessin = z.querySelector('svg');
        if (dessin) {
          dessin.setAttribute('width', '100%');
          dessin.setAttribute('height', '100%');
        }
      });
    });
  }
}

async function rafraichirInterfaceVivante() {
  if (!Execution.actif) return;
  const composants = await appelJson('/api/ui');
  // On ne redessine que si quelque chose a changé : sinon le curseur sortirait
  // des champs de saisie à chaque interrogation.
  const signature = JSON.stringify(composants);
  if (signature === Execution.signature) return;
  Execution.signature = signature;
  dessinerInterfaceVivante(composants);
}

function basculerModeExecution(actif) {
  Execution.actif = actif;
  elementConcepteur('modeExecution').checked = actif;
  elementConcepteur('toileApplication').hidden = actif;
  elementConcepteur('toileExecution').hidden = !actif;
  if (Execution.minuteur) clearInterval(Execution.minuteur);
  if (actif) {
    Execution.signature = '';
    rafraichirInterfaceVivante();
    Execution.minuteur = setInterval(rafraichirInterfaceVivante, 600);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  const bouton = document.getElementById('btnAppExecuter');
  if (!bouton) return;
  bouton.onclick = async () => {
    const nom = elementConcepteur('nomApplication').value || 'MonApplication';
    const code = produireCodeApplication();
    elementConcepteur('codeApplication').textContent = code;
    const chemin = (Atelier.dossier || '.') + '/' + nom + '.m';
    await poster('/api/fichier', { chemin: chemin, contenu: code });
    executer('rehash; ' + nom + '();');
    basculerModeExecution(true);
  };
  document.getElementById('modeExecution').onchange = (e) =>
    basculerModeExecution(e.target.checked);
});
