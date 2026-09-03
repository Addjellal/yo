function [swa, swd] = swt(x, niveaux, nom)
%SWT Transformée en ondelettes stationnaire, sans sous-échantillonnage.
%   [SWA,SWD] = SWT(X,N,NOM) rend N lignes d'approximations et N lignes
%   de détails, toutes de la longueur du signal. À chaque niveau, ce sont
%   les filtres qui sont dilatés — un zéro inséré entre deux
%   coefficients — au lieu du signal qui est décimé.
%
%   Le résultat est invariant par translation, ce que la transformée
%   décimée n'est pas : c'est ce qui la rend meilleure pour le
%   débruitage.
%
%   Exemple :
%      [a, d] = swt(1:8, 2, 'haar');
%
%   Voir aussi ISWT, SWT2, MODWT, DWT.
    if nargin < 3 || isempty(nom), nom = 'haar'; end
    % L'analyse corrèle avec les filtres d'analyse renversés, comme DWT.
    % Pour une ondelette orthogonale c'est la synthèse ; pour une
    % biorthogonale, les deux diffèrent.
    [analyseBas, analyseHaut] = wfilters(nom, 'd');
    Lo_D = analyseBas(end:-1:1);
    Hi_D = analyseHaut(end:-1:1);
    x = double(x(:)).';
    n = numel(x);
    if mod(n, 2 ^ niveaux) ~= 0
        error('wavelet:swt:BadLength', ...
              'La longueur du signal doit être un multiple de 2^N.');
    end
    swa = zeros(niveaux, n);
    swd = zeros(niveaux, n);
    courant = x;
    for k = 1:niveaux
        [bas, haut] = dilaterFiltres(Lo_D, Hi_D, k - 1);
        a = convolutionCirculaire(courant, bas);
        d = convolutionCirculaire(courant, haut);
        swa(k, :) = a;
        swd(k, :) = d;
        courant = a;
    end
end
