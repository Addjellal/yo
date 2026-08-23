/* verifierAtelier.mjs — vérification de bout en bout de l'atelier.
 *
 * Lance un vrai navigateur sur l'atelier, clique comme le ferait quelqu'un,
 * et contrôle ce qui s'affiche. Ce n'est pas « la page ne plante pas » :
 * chaque vérification compare à une valeur connue — la somme d'un carré
 * magique, le code produit par le concepteur, le lien tracé à la souris
 * dans l'éditeur de schémas, l'arrêt du débogueur sur la bonne ligne.
 *
 * Usage :  node tests/ide/verifierAtelier.mjs [adresse]
 * L'atelier doit déjà tourner ; « make verifier-atelier » s'en charge.
 */
import { createRequire } from 'node:module';

// Playwright n'est pas une dépendance du dépôt : on le cherche là où npm
// l'a posé, et on explique quoi faire s'il manque.
const exiger = createRequire(import.meta.url);
let chromium;
try {
  ({ chromium } = exiger('playwright'));
} catch (e) {
  console.log('atelier : playwright absent — « npm install playwright » puis relancer.');
  process.exit(77);
}
import { mkdtempSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const base = process.argv[2] || 'http://127.0.0.1:8421';
const executable = process.env.PLAYWRIGHT_CHROMIUM || '/opt/pw-browsers/chromium';

let echecs = 0;
function verifier(nom, condition, detail) {
  if (condition) {
    console.log('  ok   ' + nom);
  } else {
    echecs += 1;
    console.log('  ECHEC ' + nom + (detail ? ' — ' + detail : ''));
  }
}

const navigateur = await chromium.launch({ executablePath: executable,
                                           args: ['--no-proxy-server'] });
const page = await navigateur.newPage();
const erreursPage = [];
page.on('pageerror', (e) => erreursPage.push('pageerror: ' + e.message));
page.on('console', (m) => { if (m.type() === 'error') erreursPage.push('console: ' + m.text()); });

console.log('--- atelier ---');
await page.goto(base, { waitUntil: 'domcontentloaded' });
await page.waitForTimeout(800);
verifier('la page se charge', (await page.title()).indexOf('MatLibre') >= 0);

/* ------------------------------------------------------------- console */
await page.fill('#saisie', 'a = magic(4); disp(sum(a(:)))');
await page.press('#saisie', 'Enter');
await page.waitForTimeout(1200);
const sortie = await page.textContent('#sortieConsole');
verifier('la console rend la somme du carre magique 4x4 (136)', sortie.includes('136'));

/* --------------------------------------------------- espace de travail */
const variables = await page.$$eval('#tableVariables tbody tr', (lignes) =>
  lignes.map((tr) => ({ nom: tr.cells[0].textContent, classe: tr.cells[1].textContent,
                        taille: tr.cells[2].textContent })));
const varA = variables.find((v) => v.nom === 'a');
verifier('l explorateur montre a', !!varA);
verifier('a est un double 4x4', varA && varA.classe === 'double' && varA.taille === '4x4',
         varA ? varA.classe + ' ' + varA.taille : 'absente');

/* --------------------------------------------------------- coloration */
await page.fill('#editeur', "function y = f(x)\n  % commentaire\n  y = x^2 + 'texte';\nend");
await page.waitForTimeout(300);
const coloration = await page.innerHTML('#coloration');
verifier('les mots-cles sont colores', coloration.includes('class="mot">function'));
verifier('les commentaires sont colores', coloration.includes('class="commentaire"'));
verifier('les chaines sont colorees', coloration.includes('class="chaine"'));
verifier('la gouttiere numerote les 4 lignes',
         (await page.$$('#gouttiere div')).length === 4);

/* ------------------------------------------------------------ figures */
await page.fill('#saisie', "figure(); plot(1:10, (1:10).^2); title('essai')");
await page.press('#saisie', 'Enter');
await page.waitForTimeout(1200);
await page.click('.onglet[data-vue="figures"]');
await page.waitForTimeout(700);
const cadreFigure = await page.innerHTML('#cadreFigure');
verifier('la figure revient en SVG', cadreFigure.includes('svg'));

/* ---------------------------------------------------------- profileur */
await page.click('.onglet[data-vue="editeur"]');
await page.fill('#saisie', 'profile on; for k = 1:300, sqrt(k); end; profile off');
await page.press('#saisie', 'Enter');
await page.waitForTimeout(1400);
await page.click('.onglet[data-vue="profil"]');
await page.click('#btnProfilRafraichir');
await page.waitForTimeout(500);
const lignesProfil = await page.$$eval('#tableProfil tbody tr', (l) =>
  l.map((tr) => [tr.cells[0].textContent, tr.cells[1].textContent]));
const entreeSqrt = lignesProfil.find((l) => l[0] === 'sqrt');
verifier('le profileur compte 300 appels a sqrt',
         entreeSqrt && parseInt(entreeSqrt[1], 10) === 300,
         entreeSqrt ? entreeSqrt[1] : 'sqrt absent');

/* ------------------------------------------ concepteur d'applications */
await page.click('.onglet[data-vue="application"]');
await page.dblclick('#paletteComposants li[data-type="button"]');
await page.waitForTimeout(150);
await page.dblclick('#paletteComposants li[data-type="axes"]');
await page.waitForTimeout(150);
verifier('deux composants sont poses', (await page.$$('#toileApplication .composant')).length === 2);
await page.click('#btnAppCode');
const codeApplication = await page.textContent('#codeApplication');
verifier('le code appelle uifigure', codeApplication.includes('uifigure'));
verifier('le code appelle uibutton', codeApplication.includes('uibutton'));
verifier('le code appelle uiaxes', codeApplication.includes('uiaxes'));
verifier('le code se termine par end', codeApplication.trim().endsWith('end'));

/* ------------------------------------------------ editeur de schemas */
// Les fichiers produits par le concepteur et l'éditeur de schémas vont
// dans un dossier temporaire, pas dans le dépôt.
const dossierTravail = mkdtempSync(join(tmpdir(), 'matlibre-atelier-'));
await page.evaluate((d) => { window.Atelier.dossier = d; }, dossierTravail);
await page.click('.onglet[data-vue="schema"]');
await page.dblclick('#paletteBlocs li[data-type="step"]');
await page.waitForTimeout(150);
await page.dblclick('#paletteBlocs li[data-type="integrator"]');
await page.waitForTimeout(150);
// Les deux blocs arrivent au même endroit : on déplace le second à la souris.
{
  const groupes = await page.$$('#toileSchema g.bloc');
  const cadre = await groupes[groupes.length - 1].boundingBox();
  await page.mouse.move(cadre.x + cadre.width / 2, cadre.y + cadre.height / 2);
  await page.mouse.down();
  await page.mouse.move(cadre.x + 320, cadre.y + 140, { steps: 12 });
  await page.mouse.up();
  await page.waitForTimeout(250);
}
verifier('deux blocs sont poses', (await page.$$('#toileSchema g.bloc')).length === 2);

// Tirer un fil de la sortie du premier bloc vers l'entrée du second.
{
  const sortie = await page.$('#toileSchema circle.port:not(.entree)');
  const entree = await page.$('#toileSchema circle.port.entree');
  const a = await sortie.boundingBox();
  const b = await entree.boundingBox();
  await page.mouse.move(a.x + a.width / 2, a.y + a.height / 2);
  await page.mouse.down();
  await page.mouse.move(b.x + b.width / 2, b.y + b.height / 2, { steps: 12 });
  await page.mouse.up();
  await page.waitForTimeout(250);
}
verifier('le fil est trace',
         (await page.$$('#toileSchema path.lien:not(.provisoire)')).length === 1);

await page.click('#btnModeleCode');
const codeModele = await page.textContent('#codeModele');
verifier('le modele appelle new_system', codeModele.includes('new_system'));
verifier('le modele pose les deux blocs',
         codeModele.includes("'step'") && codeModele.includes("'integrator'"));
verifier('le modele relie les blocs', codeModele.includes('add_line'));

await page.click('#btnSimuler');
await page.waitForTimeout(3000);
const resultatSimulation = await page.innerHTML('#resultatSimulation');
verifier('la simulation rend une courbe', resultatSimulation.includes('svg'));

/* -------------------------------------- application vivante (registre UI) */
// On construit une petite application avec un bouton et un champ, on
// l'exécute, puis on clique dans le navigateur : le rappel doit s'exécuter
// dans l'interpréteur et modifier l'étiquette.
{
  const dossierApp = mkdtempSync(join(tmpdir(), 'matlibre-app-'));
  const fichierApp = join(dossierApp, 'appEssai.m');
  writeFileSync(fichierApp,
    'function appEssai()\n' +
    "    f = uifigure('Essai', [300 160]);\n" +
    "    etiquette = uilabel(f, 'zero', [20 100 200 22]);\n" +
    "    bouton = uibutton(f, 'Incrementer', [20 40 140 28]);\n" +
    '    compteur = 0;\n' +
    '    bouton.Callback = @(source, evenement) incrementer();\n' +
    '    function incrementer()\n' +
    '        compteur = compteur + 1;\n' +
    "        etiquette.Text = sprintf('%d', compteur);\n" +
    '    end\n' +
    'end\n');
  await page.click('.onglet[data-vue="editeur"]');
  // On vide le registre : l'atelier garde les composants entre deux essais.
  await page.fill('#saisie',
    'l = matlibre_ui_liste(); for k = 1:numel(l), matlibre_ui_supprimer(l(k).Id); end');
  await page.press('#saisie', 'Enter');
  await page.waitForTimeout(700);
  await page.fill('#saisie', "addpath('" + dossierApp + "'); rehash; appEssai()");
  await page.press('#saisie', 'Enter');
  await page.waitForTimeout(1500);
  await page.click('.onglet[data-vue="application"]');
  await page.check('#modeExecution');
  await page.waitForTimeout(900);
  const boutons = await page.$$('#toileExecution button');
  verifier('l application vivante affiche son bouton', boutons.length === 1);
  const avant = await page.textContent('#toileExecution');
  verifier('l etiquette part de zero', avant.includes('zero'), avant);
  // L'interface se redessine quand elle change : on récupère le bouton
  // juste avant chaque clic.
  for (let essai = 0; essai < 2; essai++) {
    await page.click('#toileExecution button');
    await page.waitForTimeout(1200);
  }
  const apres = await page.textContent('#toileExecution');
  verifier('deux clics font passer l etiquette a 2', apres.includes('2'), apres);
  await page.uncheck('#modeExecution');
  await page.click('.onglet[data-vue="editeur"]');
  await page.fill('#saisie', 'closeApp();');
  await page.press('#saisie', 'Enter');
  await page.waitForTimeout(600);
}

/* ----------------------------------------------------------- debogueur */
const dossier = mkdtempSync(join(tmpdir(), 'matlibre-atelier-'));
const fichier = join(dossier, 'essaiAtelier.m');
writeFileSync(fichier,
  'function y = essaiAtelier(x)\n    a = x + 1;\n    b = a * 2;\n    y = b - 3;\nend\n');
await page.click('.onglet[data-vue="editeur"]');
await page.evaluate(async (chemin) => {
  await window.ouvrirFichier(chemin);
}, fichier).catch(() => {});
// ouvrirFichier n'est pas exportée : on passe par l'API, comme le ferait un clic.
await page.evaluate(async (chemin) => {
  const donnees = await fetch('/api/fichier?chemin=' + encodeURIComponent(chemin))
    .then((r) => r.json());
  document.getElementById('editeur').value = donnees.contenu;
  document.getElementById('editeur').dispatchEvent(new Event('input'));
  document.getElementById('nomFichier').textContent = chemin;
}, fichier);
await page.waitForTimeout(300);
await page.evaluate(async (chemin) => {
  await fetch('/api/pointsarret', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ fichier: chemin, ligne: 3, action: 'poser' }),
  });
}, fichier);
await page.fill('#saisie', "addpath('" + dossier + "'); v = essaiAtelier(4)");
await page.press('#saisie', 'Enter');
await page.waitForTimeout(1500);
const etatArret = await page.textContent('#etatExecution');
verifier('le debogueur s arrete ligne 3', etatArret.indexOf('arrêté ligne 3') >= 0, etatArret);
const variablesArret = await page.$$eval('#tableVariables tbody tr', (lignes) =>
  lignes.map((tr) => tr.cells[0].textContent + '=' + tr.cells[3].textContent));
verifier('a vaut 5 a l arret', variablesArret.some((v) => v === 'a=5'),
         JSON.stringify(variablesArret));
await page.click('#btnPas');
await page.waitForTimeout(900);
verifier('le pas a pas avance ligne 4',
         (await page.textContent('#etatExecution')).indexOf('arrêté ligne 4') >= 0);
await page.click('#btnContinuer');
await page.waitForTimeout(1200);
const sortieFinale = await page.textContent('#sortieConsole');
verifier('l execution reprend et rend 7', sortieFinale.includes('v = 7'));
await page.evaluate(async () => {
  await fetch('/api/pointsarret', {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ action: 'tout' }),
  });
});

verifier('aucune erreur JavaScript', erreursPage.length === 0, erreursPage.join(' | '));

await navigateur.close();
if (echecs === 0) {
  console.log('atelier : toutes les verifications passent');
  process.exit(0);
}
console.log('atelier : ' + echecs + ' verification(s) en echec');
process.exit(1);
