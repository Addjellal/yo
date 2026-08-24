function w = modwt(x, nom, niveaux)
%MODWT Transformée en ondelettes à chevauchement maximal.
%   W = MODWT(X,NOM,N) rend N+1 lignes : les N détails, puis
%   l'approximation. Comme SWT, elle ne décime pas ; à la différence de
%   SWT, ses filtres sont divisés par racine de deux à chaque niveau, ce
%   qui conserve l'énergie : la somme des carrés des lignes vaut celle du
%   signal.
%
%   Exemple :
%      w = modwt(1:8, 'haar', 2);
%      abs(sum(sum(w.^2)) - sum((1:8).^2))   % nul
    if nargin < 2 || isempty(nom), nom = 'haar'; end
    x = double(x(:))';
    n = numel(x);
    if nargin < 3 || isempty(niveaux), niveaux = floor(log2(n)); end
    [~, ~, Lo_D, Hi_D] = wfilters(nom);
    % Normalisation MODWT : les filtres sont divisés par racine de deux.
    bas = Lo_D / sqrt(2);
    haut = Hi_D / sqrt(2);
    w = zeros(niveaux + 1, n);
    courant = x;
    for k = 1:niveaux
        [basK, hautK] = dilaterFiltres(bas, haut, k - 1);
        w(k, :) = convolutionCirculaire(courant, hautK);
        courant = convolutionCirculaire(courant, basK);
    end
    w(niveaux + 1, :) = courant;
end
