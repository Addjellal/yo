function resultats = matlibre_lancer_tests(modele, varargin)
%MATLIBRE_LANCER_TESTS Passe tous les tests d'un contrôle a posteriori.
%   Pour un VARBACKTEST, la table de RUNTESTS de MATLAB : PortfolioID,
%   VaRID, VaRLevel, puis les verdicts TL, Bin, POF, TUFF, CC, CCI, TBF et
%   TBFI.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isa(modele, 'varbacktest')
        % La table de MATLAB : un verdict par test, dans son ordre.
        tl = matlibre_var_test(modele, 'tl', varargin{:});
        noms = {'bin', 'pof', 'tuff', 'cc', 'cci', 'tbf', 'tbfi'};
        colonnes = {'Bin', 'POF', 'TUFF', 'CC', 'CCI', 'TBF', 'TBFI'};
        verdicts = cell(1, numel(noms));
        for k = 1:numel(noms)
            t = matlibre_var_test(modele, noms{k}, varargin{:});
            verdicts{k} = t.(colonnes{k});
        end
        resultats = table(string(modele.PortfolioID), string(modele.VaRID), ...
            modele.VaRLevel, tl.TL, verdicts{:}, 'VariableNames', ...
            [{'PortfolioID', 'VaRID', 'VaRLevel', 'TL'}, colonnes]);
    elseif isa(modele, 'esbacktest')
        resultats = {matlibre_es_test(modele, 'normal', 0, varargin{:}), ...
                     matlibre_es_test(modele, 't', 5, varargin{:})};
        resultats{1}.Test = 'unconditionalNormal';
        resultats{2}.Test = 'unconditionalT';
    else
        error('risque:runtests:Modele', ...
              'RUNTESTS attend un contrôle de valeur en risque ou de perte moyenne.');
    end
end
