function [temps, tensions] = solveTransient(c, tFinal, pas, sourceTemps)
%SOLVETRANSIENT Réponse temporelle par Euler implicite.
%   [T,V] = SOLVETRANSIENT(C,TFINAL,PAS) intègre le circuit ; chaque
%   condensateur est remplacé à chaque pas par une conductance C/h en
%   parallèle avec une source de courant, et chaque bobine par une
%   résistance L/h en série avec une source de tension (modèle compagnon
%   de l'intégration implicite).
%
%   SOURCETEMPS, facultative, est une poignée @(t) rendant un facteur
%   multiplicatif appliqué aux sources de tension.
    if nargin < 4
        sourceTemps = [];
    end
    n = c.noeuds;
    temps = (0:pas:tFinal).';
    tensions = zeros(numel(temps), n);
    vc = zeros(1, numel(c.composants));    % tension aux bornes des condensateurs
    il = zeros(1, numel(c.composants));    % courant dans les bobines
    for t = 1:numel(temps)
        facteur = 1;
        if ~isempty(sourceTemps)
            facteur = sourceTemps(temps(t));
        end
        sourcesTension = [];
        for k = 1:numel(c.composants)
            if strcmp(c.composants{k}.type, 'v')
                sourcesTension(end+1) = k;
            end
        end
        m = numel(sourcesTension);
        A = zeros(n + m, n + m);
        b = zeros(n + m, 1);
        for k = 1:numel(c.composants)
            comp = c.composants{k};
            a = comp.n1;
            d = comp.n2;
            switch comp.type
                case 'r'
                    g = 1 / comp.valeur;
                    A = ajouterConductance(A, a, d, g);
                case 'c'
                    g = comp.valeur / pas;
                    A = ajouterConductance(A, a, d, g);
                    source = g * vc(k);
                    if a > 0, b(a) = b(a) + source; end
                    if d > 0, b(d) = b(d) - source; end
                case 'l'
                    g = pas / comp.valeur;
                    A = ajouterConductance(A, a, d, g);
                    source = il(k);
                    if a > 0, b(a) = b(a) - source; end
                    if d > 0, b(d) = b(d) + source; end
                case 'i'
                    if a > 0, b(a) = b(a) - comp.valeur * facteur; end
                    if d > 0, b(d) = b(d) + comp.valeur * facteur; end
                case 'v'
                    j = n + find(sourcesTension == k);
                    if a > 0
                        A(a, j) = A(a, j) + 1;
                        A(j, a) = A(j, a) + 1;
                    end
                    if d > 0
                        A(d, j) = A(d, j) - 1;
                        A(j, d) = A(j, d) - 1;
                    end
                    b(j) = comp.valeur * facteur;
            end
        end
        solution = A \ b;
        v = solution(1:n);
        tensions(t, :) = v.';
        % Mise à jour des états.
        for k = 1:numel(c.composants)
            comp = c.composants{k};
            va = 0; vb = 0;
            if comp.n1 > 0, va = v(comp.n1); end
            if comp.n2 > 0, vb = v(comp.n2); end
            if strcmp(comp.type, 'c')
                vc(k) = va - vb;
            elseif strcmp(comp.type, 'l')
                il(k) = il(k) + pas / comp.valeur * (va - vb);
            end
        end
    end
end

function A = ajouterConductance(A, a, d, g)
    if a > 0, A(a, a) = A(a, a) + g; end
    if d > 0, A(d, d) = A(d, d) + g; end
    if a > 0 && d > 0
        A(a, d) = A(a, d) - g;
        A(d, a) = A(d, a) - g;
    end
end
