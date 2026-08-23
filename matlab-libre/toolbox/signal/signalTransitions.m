function transitions = signalTransitions(x, t, basPct, hautPct)
%SIGNALTRANSITIONS Découpe le signal en transitions et les mesure.
%   Rend une matrice à cinq colonnes : instant de la traversée basse,
%   instant de la traversée haute, instant de la traversée médiane,
%   polarité (+1 montante, -1 descendante) et indice de l'échantillon de
%   la traversée médiane.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 3 || isempty(basPct), basPct = 10; end
    if nargin < 4 || isempty(hautPct), hautPct = 90; end
    x = double(x(:));
    t = t(:);
    [bas, haut, seuils] = signalNiveaux(x, [basPct hautPct 50]);
    seuilBas = seuils(1);
    seuilHaut = seuils(2);
    milieu = seuils(3);
    if haut <= bas
        transitions = zeros(0, 5);
        return
    end
    [croisements, montantes] = signalTraverses(x, t, milieu);
    transitions = zeros(numel(croisements), 5);
    for k = 1:numel(croisements)
        instantMilieu = croisements(k);
        indice = find(t >= instantMilieu, 1);
        if isempty(indice), indice = numel(t); end
        polarite = 1;
        if ~montantes(k), polarite = -1; end
        if polarite > 0
            debut = traverseeAvant(x, t, indice, seuilBas);
            fin = traverseeApres(x, t, indice, seuilHaut);
        else
            debut = traverseeAvant(x, t, indice, seuilHaut);
            fin = traverseeApres(x, t, indice, seuilBas);
        end
        transitions(k, :) = [debut fin instantMilieu polarite indice];
    end
end

function instant = traverseeAvant(x, t, indice, seuil)
%TRAVERSEEAVANT Dernière traversée de SEUIL avant l'indice donné.
    instant = t(1);
    for k = indice:-1:2
        a = x(k - 1) - seuil;
        b = x(k) - seuil;
        if (a <= 0 && b >= 0) || (a >= 0 && b <= 0)
            if b == a
                instant = t(k - 1);
            else
                instant = t(k - 1) + (t(k) - t(k - 1)) * (-a) / (b - a);
            end
            return
        end
    end
end

function instant = traverseeApres(x, t, indice, seuil)
%TRAVERSEEAPRES Première traversée de SEUIL à partir de l'indice donné.
    instant = t(end);
    depart = max(1, indice - 1);
    for k = depart:numel(x) - 1
        a = x(k) - seuil;
        b = x(k + 1) - seuil;
        if (a <= 0 && b >= 0) || (a >= 0 && b <= 0)
            if b == a
                instant = t(k);
            else
                instant = t(k) + (t(k + 1) - t(k)) * (-a) / (b - a);
            end
            return
        end
    end
end
