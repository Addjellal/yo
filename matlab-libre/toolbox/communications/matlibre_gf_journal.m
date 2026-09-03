function [journal, exponentielle] = matlibre_gf_journal(m, prim)
%MATLIBRE_GF_JOURNAL Tables du logarithme discret d'un corps de Galois.
%   [LOG,EXP] = MATLIBRE_GF_JOURNAL(M,PRIM) rend deux tables de GF(2^M) :
%   LOG(V+1) est l'exposant de la valeur V — non défini pour zéro, où il
%   vaut -Inf —, et EXP(K+1) la valeur de alpha^K.
%
%   Multiplier revient alors à additionner des exposants modulo 2^M-1 :
%   c'est ce qui rend l'arithmétique du corps rapide.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    n = 2 ^ m;
    exponentielle = zeros(1, n);
    journal = -inf(1, n);
    valeur = 1;
    for k = 0:(n - 2)
        exponentielle(k + 1) = valeur;
        if journal(valeur + 1) == -Inf
            journal(valeur + 1) = k;
        end
        valeur = valeur * 2;
        if valeur >= n
            valeur = bitxor(valeur, prim);
        end
    end
    exponentielle(n) = exponentielle(1);   % alpha^(n-1) reboucle sur un
end
