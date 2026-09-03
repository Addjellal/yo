function arbre = wpdec2(x, profondeur, nom, entropie, parametre)
%WPDEC2 Décomposition d'une image en paquets d'ondelettes.
%   T = WPDEC2(X,N,NOM) décompose l'image X sur N niveaux : chaque nœud
%   est scindé en quatre — approximation et trois détails —, ce qui donne
%   un arbre complet de 4^N feuilles.
%
%   T = WPDEC2(X,N,NOM,ENT,PAR) donne le critère d'entropie que BESTTREE
%   emploiera.
%
%   L'arbre est de même forme qu'en une dimension, l'ordre valant quatre :
%   les enfants du nœud N portent les indices 4N+1 à 4N+4.
%
%   Exemple :
%      t = wpdec2(magic(16), 2, 'haar');
%      ntnode(t)                      % 16
%      max(max(abs(wprec2(t) - magic(16))))   % nul
%
%   Voir aussi WPREC2, WPDEC, WPCOEF, WPRCOEF, BESTTREE.
    if nargin < 3 || isempty(nom), nom = 'haar'; end
    if nargin < 2 || isempty(profondeur), profondeur = 1; end
    if nargin < 4 || isempty(entropie), entropie = 'shannon'; end
    if nargin < 5, parametre = []; end
    profondeur = round(profondeur);
    if profondeur < 0
        error('wavelet:wpdec2:Profondeur', 'La profondeur doit être positive.');
    end
    x = double(x);
    if ndims(x) > 2 %#ok<ISMAT>
        error('wavelet:wpdec2:Dimension', 'WPDEC2 attend une image plane.');
    end
    arbre = struct('type', 'wptree', 'dimension', 2, 'ordre', 4, ...
                   'nom', nom, 'profondeur', profondeur, ...
                   'entropie', lower(char(entropie)), 'parametre', parametre, ...
                   'taille', size(x), 'ligne', true, ...
                   'donnees', {cell(1, 1)}, 'noeuds', 0);
    arbre.donnees{1} = x;
    for niveau = 0:(profondeur - 1)
        premier = (4 ^ niveau - 1) / 3;
        for position = 0:(4 ^ niveau - 1)
            arbre = scinderNoeud(arbre, premier + position);
        end
    end
end
