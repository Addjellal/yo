function x = iswt(swa, swd, nom)
%ISWT Transformée en ondelettes stationnaire inverse.
%   X = ISWT(SWA,SWD,NOM) reconstruit le signal. Comme la transformée
%   est redondante, la reconstruction moyenne les deux décimations
%   possibles à chaque niveau.
%
%   Exemple :
%      [a, d] = swt(1:8, 2, 'haar');
%      max(abs(iswt(a, d, 'haar') - (1:8)))   % nul
%
%   Voir aussi SWT, ISWT2, IMODWT, IDWT.
    if nargin < 3 || isempty(nom), nom = 'haar'; end
    [Lo_D, Hi_D] = wfilters(nom, 'r');
    niveaux = size(swd, 1);
    if isvector(swa)
        courant = swa(:)';
    else
        courant = swa(niveaux, :);
    end
    n = numel(courant);
    for k = niveaux:-1:1
        d = swd(k, :);
        [bas, haut] = dilaterFiltres(Lo_D, Hi_D, k - 1);
        % Adjoint de la corrélation circulaire : la transformée
        % stationnaire est un cadre ajusté de constante 2, d'où le
        % facteur un demi.
        courant = (adjointCirculaire(courant, bas) + adjointCirculaire(d, haut)) / 2;
    end
    x = courant;
    n = n;                                       %#ok<ASGSL>
end

function y = adjointCirculaire(x, h)
    n = numel(x);
    m = numel(h);
    y = zeros(1, n);
    for k = 1:n
        for j = 1:m
            indice = mod(k - 1 + j - 1, n) + 1;
            y(indice) = y(indice) + h(j) * x(k);
        end
    end
end
