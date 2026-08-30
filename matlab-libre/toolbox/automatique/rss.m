function sys = rss(n, ny, nu)
%RSS Modèle d'état continu stable, tiré au hasard.
%   SYS = RSS(N) rend un modèle d'ordre N, à une entrée et une sortie,
%   dont tous les pôles sont dans le demi-plan gauche. C'est ce qu'on
%   emploie pour éprouver un algorithme sur des modèles quelconques.
%
%   SYS = RSS(N,NY) donne NY sorties ; SYS = RSS(N,NY,NU) donne aussi NU
%   entrées.
%
%   Les pôles sont tirés sur une loi normale et leur partie réelle est
%   rendue négative : le modèle est stable par construction.
%
%   Exemples :
%      sys = rss(3);
%      max(real(pole(sys))) < 0     % vrai : le modele est stable
%      isequal(size(rss(2, 3, 4)), [3 4])
%
%   Voir aussi DRSS, SS, POLE, RAND.
    if nargin < 1 || isempty(n), n = 1; end
    if nargin < 2 || isempty(ny), ny = 1; end
    if nargin < 3 || isempty(nu), nu = 1; end
    A = randn(n, n);
    % On rend la partie réelle des valeurs propres négative en retranchant
    % assez de fois l'identité.
    if n > 0
        decalage = max(real(eig(A)));
        A = A - (decalage + 0.5 + rand()) * eye(n);
    end
    sys = ss(A, randn(n, nu), randn(ny, n), zeros(ny, nu));
end
