function n = h2norm(sys)
%H2NORM Norme H2 d'un modèle stable.
%   N = H2NORM(SYS) rend l'énergie de la réponse impulsionnelle : la
%   racine de l'intégrale du carré du module de la réponse
%   fréquentielle, divisée par deux pi. C'est aussi l'écart type de la
%   sortie quand l'entrée est un bruit blanc de variance unité, ce qui
%   en fait la mesure de performance moyenne d'une boucle.
%
%   Le calcul passe par les grammiens, non par une quadrature :
%
%      ||G||_2^2 = trace(C Wc C') = trace(B' Wo B)
%
%   ce qui est exact, vaut pour les systèmes à plusieurs entrées et
%   sorties, et ne dépend d'aucune grille de fréquences.
%
%   Un modèle instable n'a pas de norme H2 finie. Un modèle continu dont
%   le terme direct n'est pas nul non plus : la réponse fréquentielle ne
%   tend pas vers zéro, et l'intégrale diverge. En discret, le terme
%   direct est admis et compte pour trace(D D').
%
%   Exemples :
%      abs(h2norm(tf(1, [1 1])) - sqrt(0.5)) < 1e-9    % la valeur exacte
%      h2norm(tf(1, [1 0.1 1])) > h2norm(tf(1, [1 2 1]))   % le peu amorti
%                                                          % en a plus
%
%      % Un modele a deux entrees et deux sorties
%      G = [tf(1, [1 1]), tf(0, 1); tf(0, 1), tf(2, [1 2])];
%      abs(h2norm(G) - sqrt(0.5 + 1)) < 1e-9
%
%   Voir aussi HINFNORM, SIGMA, COVAR, GRAM, NORM.
    modele = ss(sys);
    A = modele.A;
    B = modele.B;
    C = modele.C;
    D = modele.D;
    if isempty(A)
        if modele.Ts == 0
            n = 0;
            if max(max(abs(D))) > 0
                n = Inf;
            end
        else
            n = sqrt(trace(D * D'));
        end
        return;
    end
    poles = eig(A);
    if (modele.Ts == 0 && max(real(poles)) >= -1e-12) || ...
       (modele.Ts ~= 0 && max(abs(poles)) >= 1 - 1e-12)
        n = Inf;
        return;
    end
    if modele.Ts == 0 && max(max(abs(D))) > 1e-12
        % La reponse ne tend pas vers zero : l'integrale diverge.
        n = Inf;
        return;
    end
    Wc = gram(modele, 'c');
    valeur = trace(C * Wc * C');
    if modele.Ts ~= 0
        valeur = valeur + trace(D * D');
    end
    n = sqrt(max(valeur, 0));
end
