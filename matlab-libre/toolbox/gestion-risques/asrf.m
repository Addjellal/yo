function capital = asrf(probabiliteDefaut, perteEnCasDeDefaut, correlation, varargin)
%ASRF Capital réglementaire du modèle à facteur unique asymptotique.
%   C = ASRF(PD,LGD,R) rend le capital à immobiliser par unité
%   d'exposition, selon le modèle qui fonde les accords de Bâle : un seul
%   facteur commun explique la corrélation des défauts, et le
%   portefeuille est supposé assez fin pour que le risque propre à chaque
%   contrepartie ait disparu.
%
%   Le capital couvre la perte inattendue, non la perte totale : la perte
%   attendue est censée être déjà provisionnée, et se retranche donc.
%
%   ASRF(...,'VaRLevel',A) règle le quantile (0,999), 'EAD',E l'exposition
%   — le résultat est alors un montant —, 'CorrelationType','basel'
%   remplace R par la formule de Bâle, qui décroît quand la probabilité de
%   défaut monte.
%
%   Exemple :
%      asrf(0.01, 0.45, 0.2)                       % capital par euro prete
%      asrf(0.01, 0.45, [], 'CorrelationType', 'basel')
%
%   Voir aussi CONCENTRATIONINDICES, CREDITDEFAULTCOPULA, MERTONMODEL.
    niveau = 0.999;
    exposition = 1;
    typeCorrelation = 'valeur';
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'varlevel',        niveau = varargin{k+1};
            case 'ead',             exposition = double(varargin{k+1}(:));
            case 'correlationtype', typeCorrelation = lower(char(varargin{k+1}));
            otherwise
                error('risque:asrf:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    probabiliteDefaut = double(probabiliteDefaut(:));
    perteEnCasDeDefaut = double(perteEnCasDeDefaut(:));
    if strcmp(typeCorrelation, 'basel')
        % Formule de Bâle : la corrélation décroît de 0,24 à 0,12 quand la
        % probabilité de défaut augmente. Une contrepartie déjà fragile
        % dépend moins de la conjoncture que d'elle-même.
        poids = (1 - exp(-50 * probabiliteDefaut)) / (1 - exp(-50));
        correlation = 0.12 * poids + 0.24 * (1 - poids);
    else
        correlation = double(correlation(:));
    end
    [probabiliteDefaut, perteEnCasDeDefaut] = ...
        matlibre_diffuser_risque(probabiliteDefaut, perteEnCasDeDefaut);
    [probabiliteDefaut, correlation] = ...
        matlibre_diffuser_risque(probabiliteDefaut, correlation);
    [perteEnCasDeDefaut, correlation] = ...
        matlibre_diffuser_risque(perteEnCasDeDefaut, correlation);
    % Probabilité de défaut conditionnelle au pire état du facteur commun.
    conditionnelle = normcdf((norminv(probabiliteDefaut) + ...
                              sqrt(correlation) * norminv(niveau)) ./ ...
                             sqrt(1 - correlation));
    capital = perteEnCasDeDefaut .* (conditionnelle - probabiliteDefaut);
    if ~isscalar(exposition) || exposition ~= 1
        [capital, exposition] = matlibre_diffuser_risque(capital, exposition);
        capital = capital .* exposition;
    end
end
