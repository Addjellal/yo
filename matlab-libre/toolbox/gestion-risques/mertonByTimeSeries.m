function [probabiliteDefaut, distanceDefaut, valeurActif, volatiliteActif] = mertonByTimeSeries(capitaux, dette, taux, echeance, varargin)
%MERTONBYTIMESERIES Modèle de Merton estimé sur une série de capitalisations.
%   [PD,DD,A,SA] = MERTONBYTIMESERIES(E,L,R,T) estime la valeur et la
%   volatilité des actifs à partir d'une série de capitalisations
%   boursières, sans qu'on ait à donner la volatilité des capitaux
%   propres.
%
%   L'itération est celle de Vasicek et Kealhofer : à volatilité d'actif
%   donnée, chaque capitalisation s'inverse en une valeur d'actif ; la
%   série d'actifs ainsi obtenue donne une nouvelle volatilité ; on
%   recommence. Le point fixe est atteint en quelques tours.
%
%   Le résultat porte sur la dernière date de la série.
%
%   Exemple :
%      [pd, dd] = mertonByTimeSeries(capitalisations, dettes, 0.03, 1)
%
%   Voir aussi MERTONMODEL, ASRF.
    periodes = 252;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'periodicity', periodes = varargin{k+1};
            otherwise
                error('risque:mertonByTimeSeries:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    capitaux = double(capitaux(:));
    dette = double(dette(:));
    if isscalar(dette)
        dette = repmat(dette, size(capitaux));
    end
    taux = double(taux(:));
    if isscalar(taux)
        taux = repmat(taux, size(capitaux));
    end
    echeance = double(echeance(:));
    if isscalar(echeance)
        echeance = repmat(echeance, size(capitaux));
    end
    n = numel(capitaux);
    rendementsCapitaux = diff(log(capitaux));
    volatiliteActif = std(rendementsCapitaux) * sqrt(periodes);
    serie = capitaux + dette;
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    for iteration = 1:100
        for t = 1:n
            ecart = @(a) matlibre_bls_general(a, dette(t), taux(t), taux(t), ...
                             echeance(t), volatiliteActif) - capitaux(t);
            bas = capitaux(t);
            haut = capitaux(t) + dette(t) + 1;
            while ecart(haut) < 0 && haut < 1e12
                haut = haut * 2;
            end
            serie(t) = fzero(ecart, [bas, haut]);
        end
        nouvelle = std(diff(log(serie))) * sqrt(periodes);
        if abs(nouvelle - volatiliteActif) < 1e-10
            volatiliteActif = nouvelle;
            break
        end
        volatiliteActif = nouvelle;
    end
    valeurActif = serie;
    distanceDefaut = (log(serie(end) / dette(end)) + ...
                      (taux(end) - volatiliteActif ^ 2 / 2) * echeance(end)) / ...
                     (volatiliteActif * sqrt(echeance(end)));
    probabiliteDefaut = normcdf(-distanceDefaut);
end
