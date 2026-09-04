function texte = matlibre_formule_fourier(ordre)
%MATLIBRE_FORMULE_FOURIER Écriture d'une série de Fourier tronquée.
%   T = MATLIBRE_FORMULE_FOURIER(ORDRE) rend la formule du modèle à ORDRE
%   harmoniques : une constante, puis un cosinus et un sinus par
%   harmonique, tous multiples d'une même pulsation.
%
%   Exemple :
%      matlibre_formule_fourier(1)      % a0 + a1*cos(x*w) + b1*sin(x*w)
%
%   Voir aussi FITTYPE, FIT.
    morceaux = {'a0'};
    for k = 1:ordre
        if k == 1
            morceaux{end + 1} = sprintf('a%d*cos(x*w)', k);      %#ok<AGROW>
            morceaux{end + 1} = sprintf('b%d*sin(x*w)', k);      %#ok<AGROW>
        else
            morceaux{end + 1} = sprintf('a%d*cos(%d*x*w)', k, k);   %#ok<AGROW>
            morceaux{end + 1} = sprintf('b%d*sin(%d*x*w)', k, k);   %#ok<AGROW>
        end
    end
    texte = strjoin(morceaux, ' + ');
end
