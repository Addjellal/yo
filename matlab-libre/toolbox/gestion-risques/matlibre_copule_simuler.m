function obj = matlibre_copule_simuler(obj, nombre, varargin)
%MATLIBRE_COPULE_SIMULER Scénarios de pertes d'un modèle de crédit.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    copule = 'gaussian';
    degres = 5;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'copula',            copule = lower(char(varargin{k+1}));
            case 'degreesoffreedom',  degres = varargin{k+1};
            case 'blocksize'          % la simulation tient en mémoire
            otherwise
                error('risque:copule:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    nombre = round(nombre);
    latentes = matlibre_copule_latentes(obj.Weights, obj.FactorCorrelation, ...
                                        nombre, copule, degres);
    if isa(obj, 'creditMigrationCopula')
        obj = matlibre_migration_pertes(obj, latentes);
    else
        % Le seuil de défaut est le quantile de la loi latente elle-même :
        % normale pour la copule gaussienne, Student sinon. Transformer
        % les seuils plutôt que les variables épargne un appel de
        % répartition par scénario et par contrepartie.
        if strcmpi(copule, 't')
            seuils = tinv(obj.PD, degres).';
        else
            seuils = norminv(obj.PD).';
        end
        defauts = latentes < repmat(seuils, nombre, 1);
        obj.Losses = defauts .* repmat((obj.EAD .* obj.LGD).', nombre, 1);
        obj.PortfolioLosses = sum(obj.Losses, 2);
    end
    obj.NumScenarios = nombre;
    obj.Copula = copule;
    obj.DegreesOfFreedom = degres;
end
