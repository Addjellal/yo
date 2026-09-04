function pp = csape(x, y, conditions, valeurs)
%CSAPE Spline cubique d'interpolation, à conditions de bord choisies.
%   PP = CSAPE(X,Y) interpole par une spline cubique dont les bords
%   suivent la condition « not-a-knot » : la dérivée troisième est
%   continue au deuxième et à l'avant-dernier nœud.
%
%   PP = CSAPE(X,Y,CONDITIONS) où CONDITIONS vaut :
%     'complete' ou 'clamped'  dérivée première imposée aux deux bouts
%     'second'                 dérivée seconde imposée aux deux bouts
%     'variational', 'natural' dérivée seconde nulle aux deux bouts
%     'periodic'               la fonction et ses deux dérivées se
%                              raccordent d'un bout à l'autre
%     'not-a-knot'             le défaut
%
%   PP = CSAPE(X,Y,CONDITIONS,VALEURS) donne les valeurs imposées aux
%   bords, quand la condition en demande.
%
%   Le choix des conditions ne change rien au milieu de l'intervalle mais
%   beaucoup près des bords : une spline naturelle y perd la précision
%   qu'une spline « not-a-knot » conserve, tandis qu'une spline serrée est
%   exacte si l'on connaît vraiment les pentes.
%
%   Exemple :
%      pp = csape(0:4, sin(0:4), 'complete', [cos(0) cos(4)]);
%      abs(ppval(pp, 2.5) - sin(2.5)) < 0.01
%
%   Voir aussi SPLINE, CSAPS, SPAPS, FNVAL.
    x = double(x(:));
    y = double(y(:));
    [x, ordre] = sort(x);
    y = y(ordre);
    n = numel(x);
    if nargin < 3 || isempty(conditions)
        conditions = 'not-a-knot';
    end
    if nargin < 4
        valeurs = [0 0];
    end
    valeurs = double(valeurs);
    if numel(valeurs) < 2
        valeurs = [valeurs, valeurs];
    end
    conditions = lower(char(conditions));
    if strcmp(conditions, 'not-a-knot') || n < 4
        if strcmp(conditions, 'not-a-knot')
            pp = spline(x, y);
            return
        end
    end
    h = diff(x);
    pentes = diff(y) ./ h;
    A = zeros(n, n);
    b = zeros(n, 1);
    for i = 2:(n - 1)
        A(i, i - 1) = h(i - 1);
        A(i, i) = 2 * (h(i - 1) + h(i));
        A(i, i + 1) = h(i);
        b(i) = 6 * (pentes(i) - pentes(i - 1));
    end
    switch conditions
        case {'complete', 'clamped'}
            A(1, 1) = 2 * h(1);
            A(1, 2) = h(1);
            b(1) = 6 * (pentes(1) - valeurs(1));
            A(n, n - 1) = h(n - 1);
            A(n, n) = 2 * h(n - 1);
            b(n) = 6 * (valeurs(2) - pentes(n - 1));
        case 'second'
            A(1, 1) = 1;
            b(1) = valeurs(1);
            A(n, n) = 1;
            b(n) = valeurs(2);
        case {'variational', 'natural'}
            A(1, 1) = 1;
            A(n, n) = 1;
        case 'periodic'
            % La périodicité relie le premier nœud au dernier : le système
            % cesse d'être tridiagonal, mais reste petit.
            A = zeros(n - 1, n - 1);
            b = zeros(n - 1, 1);
            for i = 2:(n - 1)
                A(i, i - 1) = h(i - 1);
                A(i, i) = 2 * (h(i - 1) + h(i));
                A(i, i + 1 - (i == n - 1) * (n - 1)) = h(i);
                b(i) = 6 * (pentes(i) - pentes(i - 1));
            end
            A(1, 1) = 2 * (h(end) + h(1));
            A(1, 2) = h(1);
            A(1, end) = h(end);
            b(1) = 6 * (pentes(1) - pentes(end));
            m = A \ b;
            m = [m; m(1)];
            pp = matlibre_pp_depuis_valeurs(x, y, m);
            return
        case 'not-a-knot'
            pp = spline(x, y);
            return
        otherwise
            error('curvefit:csape:Conditions', ...
                  'Condition de bord inconnue : %s.', conditions);
    end
    m = A \ b;
    pp = matlibre_pp_depuis_valeurs(x, y, m);
end
