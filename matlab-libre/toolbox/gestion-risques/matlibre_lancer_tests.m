function resultats = matlibre_lancer_tests(modele, varargin)
%MATLIBRE_LANCER_TESTS Passe tous les tests d'un contrôle a posteriori.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isa(modele, 'varbacktest')
        noms = {'tl', 'bin', 'pof', 'tuff', 'cci', 'cc', 'tbfi', 'tbf'};
        resultats = cell(1, numel(noms));
        for k = 1:numel(noms)
            resultats{k} = matlibre_var_test(modele, noms{k}, varargin{:});
            resultats{k}.Test = noms{k};
        end
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
