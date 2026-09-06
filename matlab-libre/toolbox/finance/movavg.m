function [courte, longue] = movavg(cours, n1, n2)
%MOVAVG Moyennes mobiles courte et longue.
%   [COURTE,LONGUE] = MOVAVG(COURS,N1,N2) rend les moyennes mobiles de
%   COURS sur N1 et sur N2 points. [COURTE,LONGUE] = MOVAVG(COURS,N1) rend
%   deux fois la même.
%
%   La moyenne est prise sur la fenêtre qui précède, jamais sur celle qui
%   suit : au rang k elle porte sur les min(k,N) derniers points. Elle est
%   donc causale — calculable au fil de l'eau — et retardée d'environ N/2
%   points, retard qui est le prix du lissage et non un défaut réparable.
%
%   Le croisement des deux moyennes est le signal le plus ancien de
%   l'analyse technique : la courte passant au-dessus de la longue marque
%   un renversement de tendance. Toutes deux étant retardées, le
%   croisement l'est aussi, ce qui explique qu'il déclenche tard sur un
%   vrai retournement et à tort sur une oscillation.
%
%   Exemple :
%      [c, l] = movavg([1 2 3 4 5 6 7 8], 2, 4);
%
%   Voir aussi MOVMEAN, FILTER, MAXDRAWDOWN.
    cours = cours(:).';
    courte = moyenneMobile(cours, n1);
    if nargin > 2
        longue = moyenneMobile(cours, n2);
    else
        longue = courte;
    end
end

function m = moyenneMobile(x, n)
    m = zeros(size(x));
    for k = 1:numel(x)
        a = max(1, k - n + 1);
        m(k) = mean(x(a:k));
    end
end
