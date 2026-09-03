function [b, a] = invfreqs(h, w, nb, na, wt, iter, tol)
%INVFREQS Filtre analogique ajusté sur une réponse en fréquence complexe.
%   [B,A] = INVFREQS(H,W,NB,NA) cherche le numérateur d'ordre NB et le
%   dénominateur d'ordre NA, en puissances décroissantes de s, dont la
%   réponse aux pulsations W approche au mieux H au sens des moindres
%   carrés.
%
%   [B,A] = INVFREQS(H,W,NB,NA,WT) pondère chaque point.
%   [B,A] = INVFREQS(H,W,NB,NA,WT,ITER,TOL) demande ITER itérations de
%   Steiglitz et McBride, arrêtées quand les coefficients bougent de
%   moins de TOL.
%
%   C'est le pendant analogique d'INVFREQZ : le premier passage minimise
%   l'erreur d'équation |B - H A|, linéaire en les coefficients ; les
%   itérations suivantes divisent par |A| trouvé au tour précédent, ce
%   qui converge vers l'erreur de sortie |B/A - H|.
%
%   Exemple :
%      [bt, at] = besself(3, 1);
%      w = logspace(-1, 1, 100);
%      h = freqs(bt, at, w);
%      [b, a] = invfreqs(h, w, 0, 3);   % retrouve bt et at
%
%   Voir aussi INVFREQZ, FREQS, PRONY, STMCB.
    if nargin < 5 || isempty(wt), wt = ones(numel(w), 1); end
    if nargin < 6 || isempty(iter), iter = 30; end
    if nargin < 7 || isempty(tol), tol = 1e-10; end
    h = double(h(:));
    w = double(w(:));
    wt = double(wt(:));
    if numel(wt) == 1, wt = wt * ones(numel(w), 1); end
    s = 1i * w;
    % B(s) = b(1) s^nb + ... + b(nb+1) ; A(s) = s^na + a(2) s^(na-1) + ...
    puissancesB = zeros(numel(w), nb + 1);
    for i = 0:nb
        puissancesB(:, i + 1) = s .^ (nb - i);
    end
    puissancesA = zeros(numel(w), na);
    for i = 1:na
        puissancesA(:, i) = s .^ (na - i);
    end
    poidsCourant = wt;
    b = [];
    a = [];
    for tour = 1:max(1, iter)
        M = [puissancesB, -repmat(h, 1, na) .* puissancesA];
        v = h .* (s .^ na);
        racine = sqrt(poidsCourant);
        M = M .* repmat(racine, 1, size(M, 2));
        v = v .* racine;
        x = [real(M); imag(M)] \ [real(v); imag(v)];
        bNouveau = x(1:nb + 1).';
        aNouveau = [1, x(nb + 2:end).'];
        if ~isempty(a) && max(abs([bNouveau aNouveau] - [b a])) < tol
            b = bNouveau;
            a = aNouveau;
            break
        end
        b = bNouveau;
        a = aNouveau;
        reponseA = polyval(a, s);
        poidsCourant = wt ./ max(abs(reponseA) .^ 2, eps);
    end
end
