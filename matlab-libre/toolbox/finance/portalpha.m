function [alpha, rendementAjuste] = portalpha(actif, reference, liquidites, choix)
%PORTALPHA Rendement en excès, corrigé du risque.
%   [A,R] = PORTALPHA(ACTIF,REFERENCE,LIQUIDITES,CHOIX) rend l'excès de
%   rendement une fois le risque pris en compte, et le rendement ajusté
%   qui lui correspond. CHOIX vaut :
%      'xs'   excès brut sur la référence (défaut)
%      'sml'  alpha de Jensen, par la droite de marché
%      'capm' le même
%      'ml'   mesure de Modigliani : l'actif est ramené au risque de la
%             référence
%      'gh1'  mesure de Graham et Harvey : la référence est portée au
%             risque de l'actif
%      'gh2'  la variante où c'est l'actif qui est ramené
%
%   Un portefeuille peut battre son indice simplement en prenant plus de
%   risque. Corriger, c'est comparer à ce qu'aurait rapporté le même
%   risque pris passivement.
%
%   Exemple :
%      portalpha(actif, indice, 0.0002, 'sml')
%
%   Voir aussi SHARPE, INFORATIO, PORTSTATS.
    if nargin < 3 || isempty(liquidites), liquidites = 0;    end
    if nargin < 4 || isempty(choix),      choix = 'xs';      end
    actif = colonne(actif);
    reference = colonne(reference);
    liquidites = colonne(liquidites);
    if isscalar(liquidites)
        liquidites = repmat(liquidites, size(actif, 1), 1);
    end
    moyenneActif = mean(actif, 1);
    moyenneReference = mean(reference, 1);
    moyenneLiquidites = mean(liquidites, 1);
    ecartActif = std(actif, 0, 1);
    ecartReference = std(reference, 0, 1);
    switch lower(choix)
        case 'xs'
            rendementAjuste = moyenneActif;
            alpha = moyenneActif - moyenneReference;
        case {'sml', 'capm'}
            beta = zeros(1, size(actif, 2));
            for k = 1:size(actif, 2)
                covariance = cov(actif(:, k), reference(:, 1));
                beta(k) = covariance(1, 2) / covariance(2, 2);
            end
            attendu = moyenneLiquidites + beta .* (moyenneReference - moyenneLiquidites);
            alpha = moyenneActif - attendu;
            rendementAjuste = attendu + alpha;
        case {'ml', 'gh2'}
            % L'actif est ramené au risque de la référence.
            rendementAjuste = moyenneLiquidites + ...
                (moyenneActif - moyenneLiquidites) .* ecartReference ./ ecartActif;
            alpha = rendementAjuste - moyenneReference;
        case 'gh1'
            % La référence est portée au risque de l'actif.
            attendu = moyenneLiquidites + ...
                (moyenneReference - moyenneLiquidites) .* ecartActif ./ ecartReference;
            alpha = moyenneActif - attendu;
            rendementAjuste = moyenneActif;
        otherwise
            error('finance:portalpha:Choix', ...
                  'Mesure inconnue : %s.', choix);
    end
end

function x = colonne(x)
    x = double(x);
    if size(x, 1) == 1 && size(x, 2) > 1
        x = x.';
    end
end
