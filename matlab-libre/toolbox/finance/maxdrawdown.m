function [perte, debut, fin] = maxdrawdown(cours)
%MAXDRAWDOWN Perte maximale depuis un sommet.
    cours = cours(:);
    sommet = cours(1);
    indiceSommet = 1;
    perte = 0;
    debut = 1;
    fin = 1;
    for k = 1:numel(cours)
        if cours(k) > sommet
            sommet = cours(k);
            indiceSommet = k;
        end
        baisse = (sommet - cours(k)) / sommet;
        if baisse > perte
            perte = baisse;
            debut = indiceSommet;
            fin = k;
        end
    end
end
