function [message, erreurs] = decode(code, n, k, methode, H)
%DECODE Décodage en blocs linéaires, avec correction d'une erreur.
%   [MSG,ERR] = DECODE(CODE,N,K,'hamming/fmt') corrige une erreur par
%   bloc grâce au syndrome, puis extrait les K bits d'information.
%
%   La forme de la sortie suit celle de l'entrée : une matrice de N
%   colonnes rend une matrice de K colonnes, un vecteur rend un vecteur.
%
%   Un code de Hamming corrige une erreur par bloc, jamais deux : sa
%   distance minimale vaut trois, et corriger t erreurs demande une
%   distance d'au moins 2t+1. Avec deux erreurs, le syndrome désigne une
%   troisième position, et le décodage rend un mot faux — ce n'est pas un
%   défaut de la mise en œuvre, c'est la limite du code.
%
%   Exemple :
%      c = encode([1 0 1 1], 7, 4, 'hamming/fmt');
%      c(3) = 1 - c(3);
%      isequal(decode(c, 7, 4, 'hamming/fmt'), [1 0 1 1])   % vrai
%
%   Voir aussi ENCODE, HAMMGEN, SYNDTABLE.
    if nargin < 4 || isempty(methode), methode = 'hamming/fmt'; end
    if strncmpi(methode, 'hamming', 7)
        m = n - k;
        H = hammgen(m);
    end
    enMatrice = ~isvector(code) && size(code, 2) == n;
    if enMatrice
        blocs = code;
    else
        colonne = iscolumn(code) && numel(code) > 1;
        blocs = reshape(code(:)', n, [])';
    end
    erreurs = 0;
    for b = 1:size(blocs, 1)
        syndrome = mod(blocs(b, :) * H', 2);
        if any(syndrome)
            % La colonne de H égale au syndrome donne la position fautive.
            for j = 1:n
                if isequal(H(:, j)', syndrome)
                    blocs(b, j) = 1 - blocs(b, j);
                    erreurs = erreurs + 1;
                    break
                end
            end
        end
    end
    message = blocs(:, 1:k);
    if enMatrice
        return
    end
    message = reshape(message', 1, []);
    if colonne
        message = message';
    end
end
