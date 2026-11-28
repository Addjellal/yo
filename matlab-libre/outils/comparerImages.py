"""comparerImages.py — compare au pixel deux dossiers de PNG de même nom.

Usage : python3 outils/comparerImages.py AVANT_PNG APRES_PNG

Pour chaque image, le nombre de pixels qui diffèrent de plus de 40 niveaux
de gris, et leur part. C'est ainsi qu'on vérifie qu'un remaniement du
rendu ne change pas l'image : un corpus de figures écrit avant (matlibre_svg),
rendu par outils/capturer.js, puis comparé à celui d'après. Demande Pillow.
"""
import os
import sys

from PIL import Image, ImageChops


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        return 2
    avant, apres = sys.argv[1], sys.argv[2]
    for nom in sorted(os.listdir(avant)):
        if not nom.endswith('.png'):
            continue
        a = Image.open(os.path.join(avant, nom)).convert('RGB')
        b = Image.open(os.path.join(apres, nom)).convert('RGB')
        if a.size != b.size:
            print(nom, 'tailles differentes', a.size, b.size)
            continue
        ecart = ImageChops.difference(a, b).convert('L').point(lambda p: 255 if p > 40 else 0)
        n = ecart.histogram()[255]
        boite = ecart.getbbox()
        print(f'{nom} {n} pixels ({100.0 * n / (a.size[0] * a.size[1]):.3f} %) {boite or ""}')
    return 0


if __name__ == '__main__':
    sys.exit(main())
