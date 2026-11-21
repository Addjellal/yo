// capturer.js — rend en PNG chaque SVG d'un dossier, pour regarder une figure.
//
// Usage : node outils/capturer.js DOSSIER_SVG DOSSIER_PNG
//
// Chaque SVG est rendu à sa taille (width/height de la balise <svg>), au
// double de la résolution, par le Chromium de Playwright. Un navigateur neuf
// par image : un échec n'emporte pas les suivantes. Les figures s'écrivent
// avec matlibre_svg() ou print('-dsvg', ...). C'est l'outil des captures
// des cas de la littérature et des corpus avant/après du rendu.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
(async () => {
  const [entree, sortie] = process.argv.slice(2);
  if (!entree || !sortie) {
    console.error('usage : node outils/capturer.js DOSSIER_SVG DOSSIER_PNG');
    process.exit(2);
  }
  fs.mkdirSync(sortie, { recursive: true });
  for (const f of fs.readdirSync(entree).filter(n => n.endsWith('.svg')).sort()) {
    const svg = fs.readFileSync(path.join(entree, f), 'utf8');
    const w = parseInt((svg.match(/width="(\d+)/) || [0, 900])[1], 10);
    const h = parseInt((svg.match(/height="(\d+)/) || [0, 600])[1], 10);
    for (let essai = 1; essai <= 3; essai++) {
      const navigateur = await chromium.launch({ args: ['--disable-gpu'] });
      try {
        const page = await navigateur.newPage({ viewport: { width: w, height: h },
                                                deviceScaleFactor: 2 });
        await page.setContent(`<html><body style="margin:0">${svg}</body></html>`);
        await page.screenshot({ path: path.join(sortie, f.replace(/\.svg$/, '.png')) });
        console.log(f, w + 'x' + h);
        await navigateur.close();
        break;
      } catch (e) {
        await navigateur.close();
        console.log(f, 'essai', essai, 'echoue :', String(e.message).split('\n')[0]);
      }
    }
  }
})();
