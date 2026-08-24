function seuil = thselect(x, methode)
%THSELECT Choix d'un seuil de débruitage.
%   THR = THSELECT(X,METHODE) où METHODE vaut :
%     'sqtwolog'  seuil universel racine de 2 log n
%     'rigrsure'  minimise l'estimateur sans biais du risque de Stein
%     'heursure'  mélange des deux, selon l'énergie du signal
%     'minimaxi'  seuil minimax de Donoho et Johnstone
%
%   X doit être normalisé : un bruit d'écart type 1.
%
%   Exemple :
%      thselect(randn(1, 1024), 'sqtwolog')   % environ 3.7
    x = double(x(:))';
    n = numel(x);
    if n == 0
        seuil = 0;
        return
    end
    switch lower(char(methode))
        case 'sqtwolog'
            seuil = sqrt(2 * log(n));
        case 'minimaxi'
            if n <= 32
                seuil = 0;
            else
                seuil = 0.3936 + 0.1829 * log2(n);
            end
        case 'rigrsure'
            seuil = seuilSure(x);
        case 'heursure'
            % Si le signal est presque tout bruit, le SURE se trompe :
            % on retombe alors sur le seuil universel.
            energie = (sum(x .^ 2) - n) / n;
            critere = (log2(n)) ^ 1.5 / sqrt(n);
            if energie < critere
                seuil = sqrt(2 * log(n));
            else
                seuil = min(seuilSure(x), sqrt(2 * log(n)));
            end
        otherwise
            error('wavelet:thselect:UnknownMethod', 'Méthode inconnue : %s.', char(methode));
    end
end

function seuil = seuilSure(x)
%SEUILSURE Seuil minimisant l'estimateur sans biais du risque.
    n = numel(x);
    tries = sort(abs(x)) .^ 2;
    cumules = cumsum(tries);
    restants = n - 2 * (1:n) + (n - (1:n)) .* tries;
    risque = (n - 2 * (1:n) + cumules + (n - (1:n)) .* tries) / n;
    restants = restants;                              %#ok<ASGSL>
    [~, meilleur] = min(risque);
    seuil = sqrt(tries(meilleur));
end
