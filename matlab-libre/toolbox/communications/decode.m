function [message, erreurs] = decode(code, n, k, methode, H)
%DECODE Décodage en blocs linéaires, avec correction d'une erreur.
%   [MSG,ERR] = DECODE(CODE,N,K,'hamming/fmt') corrige une erreur par
%   bloc grâce au syndrome, puis extrait les K bits d'information.
%
%   Exemple :
%      c = encode([1 0 1 1], 7, 4, 'hamming/fmt');
%      c(3) = 1 - c(3);
%      isequal(decode(c, 7, 4, 'hamming/fmt'), [1 0 1 1])   % vrai
    if nargin < 4 || isempty(methode), methode = 'hamming/fmt'; end
    if strncmpi(methode, 'hamming', 7)
        m = n - k;
        H = hammgen(m);
    end
    code = code(:)';
    blocs = reshape(code, n, [])';
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
    message = reshape(blocs(:, 1:k)', 1, []);
end
