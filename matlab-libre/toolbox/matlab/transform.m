function ds = transform(magasin, fonction, varargin)
%TRANSFORM Applique une fonction à chaque morceau lu d'un magasin.
%   DS = TRANSFORM(MAGASIN,F) rend un magasin dont chaque lecture rend
%   F appliquée au morceau qu'aurait rendu MAGASIN.
%
%   La transformation est paresseuse : elle n'a lieu qu'au moment de la
%   lecture, morceau par morceau. C'est ce qui permet de décrire un
%   prétraitement — mettre à l'échelle, découper, recoder — sans jamais
%   tenir le jeu entier.
%
%   Exemple :
%      a = arrayDatastore([1; 2; 3]);
%      d = transform(a, @(x) x * 10);
%      read(d)                         % 10
%
%   Voir aussi COMBINE, DATASTORE, READ, CELLFUN.
    if ~isa(fonction, 'function_handle')
        error('MATLAB:transform:Arguments', ...
              'TRANSFORM attend un magasin et une poignee de fonction.');
    end
    ds = matlibre_magasin_transforme(magasin, fonction);
end
