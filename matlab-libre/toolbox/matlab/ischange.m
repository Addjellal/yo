function [marque, s1, s2] = ischange(a, varargin)
%ISCHANGE Repère les ruptures dans une série.
%   TF = ISCHANGE(A) marque les points où la moyenne change brusquement.
%   TF = ISCHANGE(A,'linear') cherche les ruptures de pente : chaque
%   segment est ajusté par une droite au lieu d'une constante.
%   TF = ISCHANGE(A,'variance') cherche les ruptures de dispersion.
%
%   TF = ISCHANGE(...,'MaxNumChanges',K) impose au plus K ruptures.
%   TF = ISCHANGE(...,'Threshold',T) fixe la pénalité : une rupture n'est
%   retenue que si elle fait gagner plus de T sur le coût. Par défaut la
%   pénalité vaut 3*sigma^2*log(N) — la forme du critère de Schwarz, avec
%   les trois paramètres qu'ajoute une rupture : sa position et les deux
%   moyennes de part et d'autre —, où
%   sigma est estimé sur les différences successives — 1,4826 fois leur
%   écart absolu médian, divisé par racine de deux. Cet estimateur ne voit
%   pas les marches, puisqu'une marche ne touche qu'une seule différence,
%   et c'est ce qui l'empêche de confondre le saut avec le bruit.
%
%   [TF,S1,S2] = ISCHANGE(...) rend en outre, pour chaque point, les
%   paramètres du segment auquel il appartient : la moyenne dans S1 et
%   zéro dans S2 en mode 'mean', l'ordonnée à l'origine et la pente en
%   mode 'linear'.
%
%   Le découpage est optimal, non glouton : une programmation dynamique
%   parcourt tous les découpages possibles et retient celui de moindre
%   coût. C'est ce qui la distingue d'un seuillage sur la dérivée, qui
%   voit une rupture partout où le bruit est fort et nulle part où la
%   marche est lente.
%
%   Le coût d'un segment est la somme des carrés des écarts au modèle. La
%   pénalité empêche la solution triviale — une rupture par point, de coût
%   nul — et c'est elle, et non le calcul, qui décide du nombre de
%   ruptures trouvées.
%
%   Exemple :
%      x = [ones(1, 20), 5 * ones(1, 20)];
%      find(ischange(x))                   % 21 : la marche
%      x = [1:20, 20:-1:1];
%      find(ischange(x, 'linear'))         % le sommet du toit
%
%   Voir aussi ISLOCALMAX, ISOUTLIER, FINDCHANGEPTS, MOVMEAN.
    ligne = isrow(a);
    x = double(a(:));
    n = numel(x);
    methode = 'mean';
    maxRuptures = inf;
    seuil = [];
    k = 1;
    if ~isempty(varargin) && (ischar(varargin{1}) || isstring(varargin{1})) && ...
       any(strcmpi(char(varargin{1}), {'mean', 'linear', 'variance'}))
        methode = lower(char(varargin{1}));
        k = 2;
    end
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'maxnumchanges', maxRuptures = double(varargin{k + 1});
            case 'threshold',     seuil = double(varargin{k + 1});
            otherwise
                error('MATLAB:ischange:UnknownOption', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if isempty(seuil)
        if n > 2
            sigma = 1.4826 * median(abs(diff(x))) / sqrt(2);
        else
            sigma = 0;
        end
        if sigma <= 0, sigma = sqrt(max(var(x), eps)); end
        seuil = 3 * sigma ^ 2 * log(max(n, 2));
        if strcmp(methode, 'variance')
            seuil = 3 * log(max(n, 2));
        end
    end
    minimum = 2;
    if strcmp(methode, 'linear'), minimum = 3; end

    % Programmation dynamique : cout(j) est le cout minimal du decoupage
    % des j premiers points, penalise. On garde le dernier point de coupe
    % pour reconstituer le decoupage a la fin.
    % Sommes cumulees : le cout d'un segment se lit alors en temps
    % constant, ce qui ramene le parcours de tous les decoupages de n au
    % cube a n au carre.
    cumuls = sommesCumulees(x);
    cout = inf(n + 1, 1);
    cout(1) = 0;
    nombre = zeros(n + 1, 1);
    precedent = zeros(n + 1, 1);
    for j = 1:n
        for i = 1:j
            % La longueur minimale vaut pour tous les segments, y compris
            % le premier : sans cela un point isole en tete passerait pour
            % un segment a lui seul.
            if j - i + 1 < minimum && j < n
                continue
            end
            if ~isfinite(cout(i)), continue, end
            r = coutRapide(cumuls, i, j, methode);
            candidat = cout(i) + r;
            nRuptures = nombre(i) + (i > 1);
            if i > 1, candidat = candidat + seuil; end
            if nRuptures > maxRuptures, continue, end
            if candidat < cout(j + 1) - 1e-12
                cout(j + 1) = candidat;
                precedent(j + 1) = i;
                nombre(j + 1) = nRuptures;
            end
        end
    end

    coupes = [];
    j = n + 1;
    while j > 1
        i = precedent(j);
        if i > 1, coupes(end + 1) = i; end   %#ok<AGROW>
        j = i;
    end
    coupes = sort(coupes);

    marque = false(n, 1);
    marque(coupes) = true;
    s1 = zeros(n, 1);
    s2 = zeros(n, 1);
    bornes = [1, coupes, n + 1];
    for b = 1:numel(bornes) - 1
        plage = bornes(b):bornes(b + 1) - 1;
        [p1, p2] = parametresSegment(x(plage), methode);
        s1(plage) = p1;
        s2(plage) = p2;
    end
    if ligne
        marque = marque.';
        s1 = s1.';
        s2 = s2.';
    end
end

function c = sommesCumulees(x)
% Les cinq sommes dont vivent les trois couts : n, y, y^2, t*y et t^2.
    n = numel(x);
    t = (1:n)';
    c.y = [0; cumsum(x)];
    c.yy = [0; cumsum(x .^ 2)];
    c.ty = [0; cumsum(t .* x)];
    c.t = [0; cumsum(t)];
    c.tt = [0; cumsum(t .^ 2)];
end

function r = coutRapide(c, i, j, methode)
% Le cout du segment i..j, lu dans les sommes cumulees.
    m = j - i + 1;
    sy = c.y(j + 1) - c.y(i);
    syy = c.yy(j + 1) - c.yy(i);
    switch methode
        case 'linear'
            if m < 3, r = 0; return, end
            % Les instants sont ramenes a l'origine du segment : t' = t-i+1.
            sty = (c.ty(j + 1) - c.ty(i)) - (i - 1) * sy;
            st = (c.t(j + 1) - c.t(i)) - (i - 1) * m;
            stt = (c.tt(j + 1) - c.tt(i)) - 2 * (i - 1) * (c.t(j + 1) - c.t(i)) ...
                  + (i - 1) ^ 2 * m;
            denominateur = m * stt - st ^ 2;
            if abs(denominateur) < eps, r = 0; return, end
            pente = (m * sty - st * sy) / denominateur;
            constante = (sy - pente * st) / m;
            r = syy - 2 * constante * sy - 2 * pente * sty ...
                + constante ^ 2 * m + 2 * constante * pente * st + pente ^ 2 * stt;
            r = max(r, 0);
        case 'variance'
            if m < 2, r = 0; return, end
            v = max((syy - sy ^ 2 / m) / (m - 1), 0);
            if v <= 0, r = 0; else, r = m * log(v); end
        otherwise
            r = max(syy - sy ^ 2 / m, 0);
    end
end

function r = coutSegment(y, methode)
% Le cout d'un segment : la somme des carres des ecarts au modele ajuste.
    m = numel(y);
    switch methode
        case 'linear'
            if m < 3
                r = 0;
                return
            end
            t = (1:m)';
            p = [ones(m, 1), t] \ y;
            r = sum((y - [ones(m, 1), t] * p) .^ 2);
        case 'variance'
            % Vraisemblance gaussienne a variance libre : m log(variance).
            v = var(y);
            if m < 2 || v <= 0
                r = 0;
            else
                r = m * log(v);
            end
        otherwise
            r = sum((y - mean(y)) .^ 2);
    end
end

function [p1, p2] = parametresSegment(y, methode)
    m = numel(y);
    switch methode
        case 'linear'
            if m < 2
                p1 = y(1); p2 = 0; return
            end
            t = (1:m)';
            p = [ones(m, 1), t] \ y;
            p1 = p(1); p2 = p(2);
        case 'variance'
            p1 = mean(y); p2 = var(y);
        otherwise
            p1 = mean(y); p2 = 0;
    end
end
