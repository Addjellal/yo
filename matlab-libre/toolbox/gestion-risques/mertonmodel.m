function [probabiliteDefaut, distanceDefaut, valeurActif, volatiliteActif] = mertonmodel(capitaux, volatiliteCapitaux, dette, taux, echeance, varargin)
%MERTONMODEL Probabilité de défaut par le modèle structurel de Merton.
%   [PD,DD,A,SA] = MERTONMODEL(E,SE,L,R,T) rend la probabilité de défaut,
%   la distance au défaut, la valeur des actifs et leur volatilité.
%
%   L'idée de Merton est que détenir une action revient à détenir une
%   option d'achat sur l'actif de l'entreprise, de prix d'exercice égal à
%   sa dette : si l'actif vaut moins que la dette à l'échéance, les
%   actionnaires abandonnent l'entreprise à ses créanciers. Le défaut est
%   donc l'exercice manqué de cette option.
%
%   L'actif et sa volatilité ne s'observent pas. Deux équations les
%   déterminent : la formule de Black et Scholes qui donne les capitaux
%   propres à partir de l'actif, et sa dérivée qui lie les deux
%   volatilités. Le système se résout par itération.
%
%   La distance au défaut est le nombre d'écarts types qui séparent
%   l'actif du seuil ; la probabilité de défaut en est la queue normale.
%
%   MERTONMODEL(...,'Drift',M) remplace le taux sans risque par une
%   dérive attendue.
%
%   Exemple :
%      [pd, dd] = mertonmodel(50, 0.4, 40, 0.03, 1)
%
%   Voir aussi MERTONBYTIMESERIES, ASRF, CREDITDEFAULTCOPULA.
    derive = [];
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'drift', derive = varargin{k+1};
            otherwise
                error('risque:mertonmodel:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    capitaux = double(capitaux(:));
    volatiliteCapitaux = double(volatiliteCapitaux(:));
    dette = double(dette(:));
    taux = double(taux(:));
    echeance = double(echeance(:));
    n = max([numel(capitaux), numel(volatiliteCapitaux), numel(dette), ...
             numel(taux), numel(echeance)]);
    probabiliteDefaut = zeros(n, 1);
    distanceDefaut = zeros(n, 1);
    valeurActif = zeros(n, 1);
    volatiliteActif = zeros(n, 1);
    for k = 1:n
        E = matlibre_case_risque(capitaux, k);
        sigmaE = matlibre_case_risque(volatiliteCapitaux, k);
        L = matlibre_case_risque(dette, k);
        r = matlibre_case_risque(taux, k);
        T = matlibre_case_risque(echeance, k);
        [A, sigmaA] = matlibre_merton_resoudre(E, sigmaE, L, r, T);
        valeurActif(k) = A;
        volatiliteActif(k) = sigmaA;
        if isempty(derive)
            mu = r;
        else
            mu = matlibre_case_risque(double(derive(:)), k);
        end
        distanceDefaut(k) = (log(A / L) + (mu - sigmaA ^ 2 / 2) * T) / ...
                            (sigmaA * sqrt(T));
        probabiliteDefaut(k) = normcdf(-distanceDefaut(k));
    end
end
