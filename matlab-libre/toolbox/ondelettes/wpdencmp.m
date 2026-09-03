function [xd, arbre, performance0, performanceL2] = wpdencmp(varargin)
%WPDENCMP Débruitage ou compression par paquets d'ondelettes.
%   [XD,T,PERF0,PERFL2] = WPDENCMP(X,SORH,N,NOM,CRIT,PAR,KEEPAPP)
%   décompose X en paquets sur N niveaux, cherche la meilleure base au
%   sens du critère CRIT de paramètre PAR, seuille, puis reconstruit.
%   PERF0 est le pourcentage de coefficients annulés, PERFL2 la part de
%   l'énergie gardée.
%
%   WPDENCMP(T,SORH,CRIT,PAR,KEEPAPP) part d'un arbre déjà construit.
%
%   Le seuil est celui du critère : pour 'threshold' et 'sure', c'est PAR
%   lui-même ; pour les autres, le seuil universel sigma racine de deux
%   log n, sigma étant estimé sur les coefficients les plus fins.
%
%   Chercher d'abord la meilleure base fait la différence avec WDENCMP :
%   un signal dont l'énergie est en haute fréquence y est mieux
%   concentré, donc mieux débruité.
%
%   Exemple :
%      [propre, bruite] = wnoise(3, 10, 7, 5);
%      xd = wpdencmp(bruite, 's', 4, 'db4', 'shannon', 0, 1);
%      norm(xd - propre) < norm(bruite - propre)   % vrai
%
%   Voir aussi WDENCMP, WPTHCOEF, BESTTREE, WPDEC, WENTROPY.
    if isstruct(varargin{1})
        arbre = varargin{1};
        sorh = varargin{2};
        critere = varargin{3};
        parametre = varargin{4};
        garder = varargin{5};
        estDeuxD = arbre.dimension == 2;
        if estDeuxD
            origine = lireNoeud(arbre, 0);
        else
            origine = lireNoeud(arbre, 0);
        end
    else
        if numel(varargin) < 7
            error('MATLAB:minrhs', 'Not enough input arguments.');
        end
        x = double(varargin{1});
        sorh = varargin{2};
        niveaux = varargin{3};
        nom = varargin{4};
        critere = varargin{5};
        parametre = varargin{6};
        garder = varargin{7};
        estDeuxD = ~isvector(x);
        if estDeuxD
            arbre = wpdec2(x, niveaux, nom, critere, parametre);
        else
            arbre = wpdec(x, niveaux, nom, critere, parametre);
        end
        origine = x;
    end
    arbre.entropie = lower(char(critere));
    arbre.parametre = parametre;
    arbre = besttree(arbre);
    seuil = seuilDe(arbre, critere, parametre);
    avant = coefficientsDesFeuilles(arbre);
    arbre = wpthcoef(arbre, garder, sorh, seuil);
    apres = coefficientsDesFeuilles(arbre);
    if estDeuxD
        xd = wprec2(arbre);
    else
        xd = wprec(arbre);
    end
    performance0 = 100 * sum(apres == 0) / max(numel(apres), 1);
    energie = sum(avant .^ 2);
    if energie > 0
        performanceL2 = 100 * sum(apres .^ 2) / energie;
    else
        performanceL2 = 100;
    end
    if nargout < 2
        clear arbre
    end
    origine = origine;   %#ok<ASGSL,NASGU>
end

function seuil = seuilDe(arbre, critere, parametre)
%SEUILDE Le seuil que le critère commande.
    critere = lower(char(critere));
    if any(strcmp(critere, {'threshold', 'sure'})) && ~isempty(parametre)
        seuil = parametre;
        return
    end
    % Seuil universel : sigma racine de deux log n, sigma étant lu sur
    % les coefficients les plus fins, ceux qui sont presque tous du bruit.
    coefficients = coefficientsDesFeuilles(arbre);
    if isempty(coefficients)
        seuil = 0;
        return
    end
    sigma = median(abs(coefficients)) / 0.6745;
    seuil = sigma * sqrt(2 * log(max(numel(coefficients), 2)));
end

function v = coefficientsDesFeuilles(arbre)
%COEFFICIENTSDESFEUILLES Tous les coefficients terminaux, mis bout à bout.
    v = [];
    feuilles = leaves(arbre);
    for k = 1:numel(feuilles)
        donnees = lireNoeud(arbre, feuilles(k));
        v = [v, donnees(:).'];   %#ok<AGROW>
    end
end
