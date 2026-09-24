function sys = matlibre_monovoie(sys, quoi, ailleurs)
%MATLIBRE_MONOVOIE Refuse un modèle à plusieurs voies, en le nommant.
%   SYS = MATLIBRE_MONOVOIE(SYS,QUOI) rend le modèle tel quel s'il a une
%   entrée et une sortie, et échoue sinon en disant quel calcul ne vaut
%   que pour une voie.
%
%   Une marge de gain, une bande passante sont des notions de boucle
%   monovariable. Appliquées à une matrice de transfert, elles rendaient
%   un nombre calculé sur un tableau aplati : il avait l'air d'une marge
%   et n'en était pas une. SYS(I,J) choisit la voie qu'on veut mesurer.
%
%   MATLIBRE_MONOVOIE(SYS,QUOI,AILLEURS) ajoute au message le nom de la
%   fonction qui, elle, traite le cas multivariable.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_monovoie(tf(1, [1 1]), 'MARGIN');   % passe : une seule voie
%
%   Voir aussi ISSISO, MARGIN, BANDWIDTH, LOOPMARGIN.
    if isnumeric(sys)
        return
    end
    modele = ss(sys);
    ny = size(modele.D, 1);
    nu = size(modele.D, 2);
    if ny == 1 && nu == 1
        return
    end
    suite = '';
    if nargin >= 3 && ~isempty(ailleurs)
        suite = sprintf(' Pour une boucle multivariable, voyez %s.', upper(char(ailleurs)));
    end
    error('Control:analysis:RequiresSISO', ...
          ['%s ne vaut que pour un modele a une entree et une sortie ; celui-ci ' ...
           'en a %d et %d. SYS(I,J) choisit la voie a mesurer.%s'], ...
          upper(char(quoi)), nu, ny, suite);
end
