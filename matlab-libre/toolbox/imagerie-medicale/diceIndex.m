function d = diceIndex(a, b)
%DICEINDEX Indice de Dice entre deux segmentations binaires.
%   D = DICEINDEX(A,B) rend deux fois l'aire commune divisée par la somme
%   des deux aires. Il vaut un quand les deux segmentations coïncident,
%   zéro quand elles ne se touchent pas.
%
%   C'est la mesure de référence pour comparer une segmentation
%   automatique à celle d'un radiologue. Elle pénalise plus durement les
%   petites structures que les grandes : manquer dix pixels sur cent coûte
%   bien plus que dix sur mille, ce qui est voulu.
%
%   Le Dice n'est pas la proportion de pixels bien classés : sur une image
%   où la lésion occupe un pour cent de la surface, tout marquer comme
%   fond donne 99 %% de bonne classification et un Dice nul. C'est
%   précisément pourquoi on emploie l'un plutôt que l'autre.
%
%   Exemple :
%      a = false(10); a(3:7, 3:7) = true;
%      diceIndex(a, a)                 % 1 : identiques
%      b = false(10); b(5:9, 5:9) = true;
%      diceIndex(a, b)                 % le recouvrement partiel
%      diceIndex(a, ~a)                % 0 : disjointes
%
%   Voir aussi HAUSDORFFDIST, BWLABEL, IMBINARIZE.
    a = logical(a);
    b = logical(b);
    intersection = sum(sum(a & b));
    d = 2 * intersection / max(sum(a(:)) + sum(b(:)), eps);
end
