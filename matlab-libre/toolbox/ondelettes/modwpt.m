function [w, energies] = modwpt(x, varargin)
%MODWPT Paquets d'ondelettes à chevauchement maximal.
%   W = MODWPT(X) décompose X en paquets sans décimation, jusqu'au niveau
%   quatre : W a 2^4 lignes, toutes de la longueur du signal, rangées par
%   bande de fréquence croissante.
%
%   W = MODWPT(X,NIVEAU) impose le niveau ; W = MODWPT(X,NOM) ou
%   MODWPT(X,NOM,NIVEAU) choisit l'ondelette ('fk18' n'existe pas ici ;
%   'sym4' est le défaut).
%
%   [W,E] = MODWPT(...) rend en outre l'énergie relative de chaque bande.
%   Leur somme vaut un : comme la MODWT, la transformée conserve
%   l'énergie.
%
%   Les lignes sont en ordre de séquence, non en ordre naturel : à chaque
%   scission, un nœud de rang impair échange ses deux voies, ce qui remet
%   les bandes dans l'ordre des fréquences. Sans cette permutation, la
%   ligne K ne correspondrait pas à la K-ième bande.
%
%   Exemple :
%      t = (0:1023) / 1024;
%      x = sin(2 * pi * 100 * t);
%      [w, e] = modwpt(x, 3);
%      [~, k] = max(e);               % la bande qui porte le ton
%
%   Voir aussi IMODWPT, MODWT, WPDEC, MODWTMRA.
    nom = 'sym4';
    niveaux = 4;
    for k = 1:numel(varargin)
        argument = varargin{k};
        if ischar(argument) || isstring(argument)
            nom = char(argument);
        elseif isnumeric(argument) && isscalar(argument)
            niveaux = round(argument);
        end
    end
    x = double(x(:)).';
    n = numel(x);
    if niveaux < 1
        error('wavelet:modwpt:Niveau', 'Le niveau doit valoir au moins un.');
    end
    [analyseBas, analyseHaut] = wfilters(nom, 'd');
    bas = analyseBas(end:-1:1) / sqrt(2);
    haut = analyseHaut(end:-1:1) / sqrt(2);
    courant = x;
    for niveau = 1:niveaux
        [basK, hautK] = dilaterFiltres(bas, haut, niveau - 1);
        precedent = courant;
        courant = zeros(size(precedent, 1) * 2, n);
        for noeud = 0:(size(precedent, 1) - 1)
            ligne = precedent(noeud + 1, :);
            % Un nœud de rang impair échange ses deux voies : c'est ce
            % qui garde les bandes dans l'ordre des fréquences.
            if mod(noeud, 2) == 0
                courant(2 * noeud + 1, :) = convolutionCirculaire(ligne, basK);
                courant(2 * noeud + 2, :) = convolutionCirculaire(ligne, hautK);
            else
                courant(2 * noeud + 1, :) = convolutionCirculaire(ligne, hautK);
                courant(2 * noeud + 2, :) = convolutionCirculaire(ligne, basK);
            end
        end
    end
    w = courant;
    if nargout > 1
        parBande = sum(w .^ 2, 2);
        total = sum(parBande);
        if total > 0
            energies = parBande / total;
        else
            energies = parBande;
        end
    end
end
