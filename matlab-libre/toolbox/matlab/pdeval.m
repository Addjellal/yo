function [uout, duoutdx] = pdeval(m, xmesh, ui, xout)
%PDEVAL Évalue la solution de PDEPE entre les points du maillage.
%   UOUT = PDEVAL(M,XMESH,UI,XOUT) interpole en XOUT la composante UI de
%   la solution rendue par PDEPE sur le maillage XMESH.
%   [UOUT,DUOUTDX] = PDEVAL(...) rend aussi la dérivée en espace.
%
%   L'interpolation est cubique d'Hermite : sur chaque maille, le
%   polynôme prend aux deux bouts la valeur du nœud et une pente déduite
%   de la parabole passant par lui et ses deux voisins. Deux conséquences
%   qui font tout l'intérêt du procédé : la dérivée rendue est celle de la
%   fonction rendue — elles ne peuvent pas se contredire —, et l'ensemble
%   est exact sur les paraboles, donc d'ordre deux en dérivée comme la
%   discrétisation dont la solution vient.
%
%   Une interpolation affine, elle, donnerait une dérivée constante par
%   morceaux, discontinue aux nœuds et d'ordre un : elle perdrait la
%   précision que PDEPE a mise à obtenir.
%
%   M ne sert pas au calcul : il est accepté pour que l'appel ait la même
%   forme que celui de PDEPE, dont la solution vient.
%
%   Exemple :
%      x = linspace(0, 1, 21);
%      u = sin(pi * x);
%      [v, dv] = pdeval(0, x, u, 0.25);
%      abs(v - sin(pi * 0.25)) < 1e-3
%      abs(dv - pi * cos(pi * 0.25)) < 1e-2
%
%   Voir aussi PDEPE, INTERP1, DEVAL, PCHIP.
    (m);   %#ok<VUNUS>
    x = double(xmesh(:))';
    u = double(ui(:))';
    xq = double(xout);
    N = numel(x);
    if numel(u) ~= N
        error('MATLAB:pdeval:tailles', 'UI doit avoir autant de valeurs que XMESH.');
    end
    if N < 2
        error('MATLAB:pdeval:maillage', 'XMESH doit compter au moins deux points.');
    end

    pentes = matlibre_pdeval_pentes(x, u);
    uout = zeros(size(xq));
    duoutdx = zeros(size(xq));
    for k = 1:numel(xq)
        i = matlibre_pdeval_maille(x, xq(k));
        h = x(i + 1) - x(i);
        s = (xq(k) - x(i)) / h;
        % La base d'Hermite : deux fonctions portent les valeurs, deux les
        % pentes, et chacune vaut un la ou elle doit et zero ailleurs.
        h00 =  2*s^3 - 3*s^2 + 1;
        h10 =      s^3 - 2*s^2 + s;
        h01 = -2*s^3 + 3*s^2;
        h11 =      s^3 -   s^2;
        uout(k) = h00 * u(i) + h10 * h * pentes(i) + ...
                  h01 * u(i + 1) + h11 * h * pentes(i + 1);
        d00 = ( 6*s^2 - 6*s) / h;
        d10 = ( 3*s^2 - 4*s + 1);
        d01 = (-6*s^2 + 6*s) / h;
        d11 = ( 3*s^2 - 2*s);
        duoutdx(k) = d00 * u(i) + d10 * pentes(i) + ...
                     d01 * u(i + 1) + d11 * pentes(i + 1);
    end
end

function p = matlibre_pdeval_pentes(x, u)
% La pente en chaque noeud, prise sur la parabole qui passe par lui et ses
% deux voisins : exacte sur les paraboles, quel que soit l'espacement.
    N = numel(x);
    p = zeros(1, N);
    for i = 2:N-1
        hg = x(i) - x(i - 1);
        hd = x(i + 1) - x(i);
        dg = (u(i) - u(i - 1)) / hg;
        dd = (u(i + 1) - u(i)) / hd;
        p(i) = (hd * dg + hg * dd) / (hg + hd);
    end
    if N == 2
        p(1) = (u(2) - u(1)) / (x(2) - x(1));
        p(2) = p(1);
        return
    end
    % Aux bouts, la meme parabole, derivee la ou elle s'arrete.
    p(1) = matlibre_pdeval_bout(x(1), x(2), x(3), u(1), u(2), u(3));
    p(N) = matlibre_pdeval_bout(x(N), x(N-1), x(N-2), u(N), u(N-1), u(N-2));
end

function d = matlibre_pdeval_bout(x0, x1, x2, u0, u1, u2)
% La derivee en x0 de la parabole passant par les trois points.
    h1 = x1 - x0;
    h2 = x2 - x0;
    d = -(u0 * (h1 + h2) / (h1 * h2) + u1 * h2 / (h1 * (h1 - h2)) + ...
          u2 * h1 / (h2 * (h2 - h1)));
end

function i = matlibre_pdeval_maille(x, xq)
% La maille qui contient xq ; hors du maillage, on prolonge la maille du
% bord plutot que de refuser -- c'est ce que fait MATLAB.
    N = numel(x);
    i = find(x <= xq, 1, 'last');
    if isempty(i)
        i = 1;
    elseif i >= N
        i = N - 1;
    end
end
