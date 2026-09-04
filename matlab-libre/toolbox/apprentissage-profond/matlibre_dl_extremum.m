function [y, indices] = matlibre_dl_extremum(genre, a, b, arguments)
%MATLIBRE_DL_EXTREMUM Maximum ou minimum d'un DLARRAY, avec sa dérivée.
%   [Y,I] = MATLIBRE_DL_EXTREMUM(GENRE,A,B,ARGUMENTS) traite les deux
%   formes : comparaison terme à terme de A et B, ou extremum le long
%   d'une dimension. La dérivée ne passe que par l'opérande qui a gagné —
%   c'est ce qui fait du redresseur MAX(X,0) une fonction dérivable
%   presque partout.
%
%   Exemple :
%      y = matlibre_dl_extremum('max', dlarray([-1 2]), 0, {});
%      extractdata(y)     % 0 2
%
%   Voir aussi DLARRAY, RELU.
    va = matlibre_dl_valeur(a);
    if ~isempty(b)
        vb = matlibre_dl_valeur(b);
        if strcmp(genre, 'max')
            valeur = max(va, vb);
        else
            valeur = min(va, vb);
        end
        indices = [];
        y = matlibre_dl_binaire('extremumTermeATerme', a, b, valeur, ...
                                {va, vb, genre});
        return
    end
    dimension = matlibre_dl_dimension(va, arguments);
    if dimension == 0
        if strcmp(genre, 'max')
            [valeur, position] = max(va(:));
        else
            [valeur, position] = min(va(:));
        end
        indices = position;
        y = matlibre_dl_unaire('extremumTotal', a, valeur, {size(va), position});
        return
    end
    if strcmp(genre, 'max')
        [valeur, indices] = max(va, [], dimension);
    else
        [valeur, indices] = min(va, [], dimension);
    end
    y = matlibre_dl_unaire('extremumDimension', a, valeur, ...
                           {size(va), dimension, indices});
end
