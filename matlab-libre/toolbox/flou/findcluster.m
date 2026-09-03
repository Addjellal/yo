function [centres, U] = findcluster(donnees, nClusters, methode)
%FINDCLUSTER Classification floue d'un jeu de données.
%   [C,U] = FINDCLUSTER(X,N) partage les lignes de X en N classes par les
%   c-moyennes floues, et rend les centres et les appartenances.
%   [C,U] = FINDCLUSTER(X,RA,'subtractive') emploie la classification
%   soustractive de Chiu, RA étant le rayon d'influence : le nombre de
%   classes sort alors du calcul.
%
%   FINDCLUSTER(...) sans sortie demandée trace le nuage et ses centres.
%
%   MATLAB ouvre ici une application où l'on charge un fichier et déplace
%   des curseurs. MatLibre n'a pas d'application interactive : il fait le
%   calcul et montre le résultat.
%
%   Exemple :
%      nuage = [randn(40, 2); randn(40, 2) + 6];
%      c = findcluster(nuage, 2);
%      size(c, 1)                     % 2
%
%   Voir aussi FCM, SUBCLUST, GENFIS, FCMOPTIONS.
    if nargin < 3 || isempty(methode), methode = 'fcm'; end
    if nargin < 2 || isempty(nClusters), nClusters = 2; end
    donnees = double(donnees);
    methode = lower(char(methode));
    switch methode
        case 'fcm'
            [centres, U] = fcm(donnees, nClusters);
        case {'subtractive', 'subclust'}
            centres = subclust(donnees, nClusters);
            U = appartenancesAuxCentres(donnees, centres);
        otherwise
            error('fuzzy:findcluster:Methode', ...
                  'Méthode inconnue : %s.', methode);
    end
    if nargout == 0
        if size(donnees, 2) >= 2
            plot(donnees(:, 1), donnees(:, 2), '.');
            hold on;
            plot(centres(:, 1), centres(:, 2), 'ro');
            hold off;
        else
            plot(donnees, zeros(size(donnees)), '.');
        end
        title('Classification floue');
        clear centres U
    end
end

function U = appartenancesAuxCentres(donnees, centres)
%APPARTENANCESAUXCENTRES Degrés d'appartenance, exposant deux.
%   Sans exposant donné, on prend celui des c-moyennes par défaut : le
%   degré est l'inverse du carré de la distance, normalisé.
    n = size(donnees, 1);
    c = size(centres, 1);
    U = zeros(c, n);
    for i = 1:c
        ecarts = donnees - repmat(centres(i, :), n, 1);
        U(i, :) = sum(ecarts .^ 2, 2)';
    end
    U = max(U, realmin);
    U = 1 ./ U;
    U = U ./ repmat(sum(U, 1), c, 1);
end
