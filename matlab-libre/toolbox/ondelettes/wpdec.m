function arbre = wpdec(x, profondeur, nom, entropie, parametre)
%WPDEC Décomposition en paquets d'ondelettes.
%   T = WPDEC(X,N,NOM) décompose le signal X sur N niveaux en paquets
%   d'ondelettes : à la différence de WAVEDEC, qui ne redécompose que
%   l'approximation, chaque nœud est scindé en deux — approximation et
%   détail —, ce qui donne un arbre complet de 2^N feuilles.
%
%   L'intérêt est la résolution en fréquence : un signal dont l'énergie
%   est dans les hautes fréquences, qu'une décomposition en ondelettes
%   laisserait dans un seul détail large, se trouve ici finement découpé.
%
%   T = WPDEC(X,N,NOM,ENT,PAR) donne le critère d'entropie que BESTTREE
%   emploiera : 'shannon' (défaut), 'threshold' avec son seuil, 'norm'
%   avec sa puissance, 'log energy', 'sure' avec son seuil.
%
%   L'arbre rendu est une structure : « type » vaut 'wptree', « donnees »
%   porte un nœud par case — la racine à l'indice zéro, les enfants du
%   nœud N aux indices 2N+1 et 2N+2 —, et « noeuds » la liste de ceux qui
%   existent.
%
%   Exemple :
%      t = wpdec(1:64, 3, 'db2');
%      numel(leaves(t))               % 8
%      max(abs(wprec(t) - (1:64)))    % nul : la reconstruction est exacte
%
%   Voir aussi WPREC, WPCOEF, WPRCOEF, WPSPLT, WPJOIN, BESTTREE, WPDEC2.
    if nargin < 3 || isempty(nom), nom = 'haar'; end
    if nargin < 2 || isempty(profondeur), profondeur = 1; end
    if nargin < 4 || isempty(entropie), entropie = 'shannon'; end
    if nargin < 5, parametre = []; end
    profondeur = round(profondeur);
    if profondeur < 0
        error('wavelet:wpdec:Profondeur', 'La profondeur doit être positive.');
    end
    estLigne = ~iscolumn(x);
    x = double(x(:)).';
    arbre = struct('type', 'wptree', 'dimension', 1, 'ordre', 2, ...
                   'nom', nom, 'profondeur', profondeur, ...
                   'entropie', lower(char(entropie)), 'parametre', parametre, ...
                   'longueur', numel(x), 'ligne', estLigne, ...
                   'donnees', {cell(1, 1)}, 'noeuds', 0);
    arbre.donnees{1} = x;
    for niveau = 0:(profondeur - 1)
        premier = 2 ^ niveau - 1;
        for position = 0:(2 ^ niveau - 1)
            arbre = scinderNoeud(arbre, premier + position);
        end
    end
end
