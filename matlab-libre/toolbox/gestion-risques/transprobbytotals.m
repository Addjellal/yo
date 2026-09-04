function [matrice, totaux] = transprobbytotals(totauxEntree, varargin)
%TRANSPROBBYTOTALS Matrice de transition tirée de comptages agrégés.
%   [P,T] = TRANSPROBBYTOTALS(TOTAUX) rend la matrice de transition sans
%   repasser par les données individuelles. TOTAUX est la structure que
%   rend TRANSPROB, ou un tableau de telles structures : elles sont alors
%   additionnées avant l'estimation.
%
%   C'est ainsi qu'on combine des historiques venus de sources
%   différentes, ou qu'on recalcule une matrice sur un autre intervalle
%   sans relire les migrations.
%
%   Exemple :
%      [~, t] = transprob(donnees);
%      transprobbytotals(t)
%
%   Voir aussi TRANSPROB, TRANSPROBTOTHRESHOLDS.
    intervalle = 1;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'transinterval', intervalle = varargin{k+1};
            otherwise
                error('risque:transprobbytotals:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if isstruct(totauxEntree) && numel(totauxEntree) > 1
        cumul = totauxEntree(1);
        for j = 2:numel(totauxEntree)
            cumul.totalsMat = cumul.totalsMat + totauxEntree(j).totalsMat;
            if isfield(cumul, 'timeSpent')
                cumul.timeSpent = cumul.timeSpent + totauxEntree(j).timeSpent;
            end
        end
        totaux = cumul;
    else
        totaux = totauxEntree(1);
    end
    if strcmp(totaux.algorithm, 'duration')
        matrice = matlibre_generateur_vers_transition(totaux.totalsMat, ...
                                                      totaux.timeSpent, intervalle);
    else
        matrice = matlibre_normaliser_lignes(totaux.totalsMat);
    end
end
