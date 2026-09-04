function [variances, memeChose] = matlibre_garch_prevoir(obj, horizon, varargin)
%MATLIBRE_GARCH_PREVOIR Prévision de la variance conditionnelle.
%   Le niveau d'un GARCH n'est pas prévisible — la prévision de la série
%   est l'écart moyen, rien de plus. Ce qui se prévoit, c'est la
%   variance : FORECAST rend donc les variances attendues, qui convergent
%   vers la variance de long terme.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    historique = [];
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'y0', historique = double(varargin{k+1});
            case {'e0', 'v0'}
            otherwise
                error('econ:garch:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    modele = matlibre_garch_verifier(obj);
    if isempty(historique)
        error('econ:garch:Historique', ...
              'FORECAST demande la série observée, passée par ''Y0''.');
    end
    if size(historique, 1) == 1
        historique = historique.';
    end
    garchs = cell2mat(modele.GARCH);
    archs = cell2mat(modele.ARCH);
    p = numel(garchs);
    q = numel(archs);
    chemins = size(historique, 2);
    variances = zeros(horizon, chemins);
    for c = 1:chemins
        depart = var(historique(:, c) - modele.Offset);
        [passees, innovations] = matlibre_garch_variances(historique(:, c), ...
            modele.Constant, garchs, archs, modele.Offset, depart);
        n = numel(passees);
        prolonge = [passees; zeros(horizon, 1)];
        carres = [innovations .^ 2; zeros(horizon, 1)];
        for h = 1:horizon
            t = n + h;
            valeur = modele.Constant;
            for i = 1:p
                valeur = valeur + garchs(i) * prolonge(t - i);
            end
            for j = 1:q
                if t - j <= n
                    valeur = valeur + archs(j) * carres(t - j);
                else
                    % Au-delà de l'échantillon, l'espérance du carré de
                    % l'innovation est la variance conditionnelle.
                    valeur = valeur + archs(j) * prolonge(t - j);
                end
            end
            prolonge(t) = valeur;
        end
        variances(:, c) = prolonge((n + 1):(n + horizon));
    end
    memeChose = variances;
end
