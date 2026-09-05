function modele = pem(donnees, initial, varargin)
%PEM Estimation par minimisation de l'erreur de prédiction.
%   M = PEM(Z,M0) affine le modèle M0 sur les données Z, quelle que soit
%   sa famille : polynomiale ou d'état.
%   M = PEM(Z,[na nb nc nd nf nk]) estime un modèle polynomial de ces
%   ordres, comme POLYEST.
%   M = PEM(Z,N) estime un modèle d'état d'ordre N, comme SSEST.
%
%   Toutes les méthodes d'estimation de cette boîte à outils reviennent à
%   la même idée : chercher le modèle qui rend l'erreur de prédiction la
%   plus petite. Elles ne diffèrent que par la famille où l'on cherche et
%   par la façon de démarrer.
%
%   Exemple :
%      m = pem(z, [2 2 2 0 0 1]);
%
%   Voir aussi POLYEST, SSEST, ARX, ARMAX, OE, BJ.
    if isa(initial, 'idpoly')
        ordres = initial.Ordres;
        if isempty(ordres)
            ordres = [numel(initial.A) - 1, numel(initial.B) - matlibre_id_retard(initial.B), ...
                      numel(initial.C) - 1, numel(initial.D) - 1, numel(initial.F) - 1, ...
                      matlibre_id_retard(initial.B)];
        end
        modele = matlibre_id_estimer(donnees, ordres, 'pem', varargin);
        return
    end
    if isa(initial, 'idss')
        modele = ssest(donnees, size(initial.A, 1), varargin{:});
        return
    end
    if isscalar(initial)
        modele = ssest(donnees, initial, varargin{:});
        return
    end
    modele = polyest(donnees, initial, varargin{:});
end
