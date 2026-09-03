function arbre = wpthcoef(arbre, garderApproximation, sorh, seuil)
%WPTHCOEF Seuillage des coefficients d'un arbre de paquets.
%   T = WPTHCOEF(T,KEEPAPP,SORH,THR) seuille les coefficients de toutes
%   les feuilles au seuil THR, par seuillage doux ('s') ou dur ('h').
%   KEEPAPP non nul laisse intacte la feuille d'approximation — celle
%   qu'on atteint en ne prenant que des passe-bas —, dont les
%   coefficients portent la forme générale du signal.
%
%   Exemple :
%      t = wpdec(1:64, 3, 'db2');
%      ts = wpthcoef(t, 1, 's', 2);
%      norm(wprec(ts) - (1:64)) > 0   % le signal a changé
%
%   Voir aussi WTHRESH, WPDENCMP, BESTTREE, WPDEC.
    if nargin < 2 || isempty(garderApproximation), garderApproximation = 1; end
    if nargin < 3 || isempty(sorh), sorh = 's'; end
    if nargin < 4 || isempty(seuil), seuil = 0; end
    feuilles = leaves(arbre);
    % La feuille d'approximation est celle dont le chemin ne prend que la
    % première voie : son indice est le plus petit de sa profondeur.
    for k = 1:numel(feuilles)
        indice = feuilles(k);
        if garderApproximation && estApproximation(arbre, indice)
            continue
        end
        donnees = lireNoeud(arbre, indice);
        arbre = poserNoeud(arbre, indice, wthresh(donnees, sorh, seuil));
    end
end

function oui = estApproximation(arbre, indice)
%ESTAPPROXIMATION Le nœud est-il au bout du chemin tout passe-bas.
    courant = indice;
    oui = true;
    while courant > 0
        if mod(courant - 1, arbre.ordre) ~= 0
            oui = false;
            return
        end
        courant = floor((courant - 1) / arbre.ordre);
    end
end
