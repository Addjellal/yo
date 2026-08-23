function [b, a] = invfreqz(h, w, nb, na, wt, iter, tol)
%INVFREQZ Filtre numérique ajusté sur une réponse en fréquence complexe.
%   [B,A] = INVFREQZ(H,W,NB,NA) cherche le numérateur d'ordre NB et le
%   dénominateur d'ordre NA dont la réponse aux pulsations W approche au
%   mieux H, au sens des moindres carrés.
%
%   [B,A] = INVFREQZ(H,W,NB,NA,WT) pondère chaque point.
%   [B,A] = INVFREQZ(H,W,NB,NA,WT,ITER,TOL) demande ITER itérations de
%   Steiglitz et McBride, arrêtées quand les coefficients bougent de
%   moins de TOL.
%
%   Le premier passage minimise l'erreur d'équation |B - H A|, qui est
%   linéaire en les coefficients mais pondère mal les fréquences où A est
%   petit. Les itérations suivantes divisent par |A| trouvé au tour
%   précédent : on converge alors vers l'erreur de sortie |B/A - H|,
%   celle qui compte.
%
%   Exemple :
%      [bt, at] = butter(4, 0.3);
%      [h, w] = freqz(bt, at, 256);
%      [b, a] = invfreqz(h, w, 4, 4);   % retrouve bt et at
    if nargin < 5 || isempty(wt), wt = ones(numel(w), 1); end
    if nargin < 6 || isempty(iter), iter = 30; end
    if nargin < 7 || isempty(tol), tol = 1e-10; end
    h = double(h(:));
    w = double(w(:));
    wt = double(wt(:));
    if numel(wt) == 1, wt = wt * ones(numel(w), 1); end
    z = exp(-1i * w);
    puissancesB = zeros(numel(w), nb + 1);
    for i = 0:nb
        puissancesB(:, i + 1) = z .^ i;
    end
    puissancesA = zeros(numel(w), na);
    for i = 1:na
        puissancesA(:, i) = z .^ i;
    end
    poidsCourant = wt;
    b = [];
    a = [];
    for tour = 1:max(1, iter)
        M = [puissancesB, -repmat(h, 1, na) .* puissancesA];
        v = h;
        racine = sqrt(poidsCourant);
        M = M .* repmat(racine, 1, size(M, 2));
        v = v .* racine;
        % Moindres carrés complexes ramenés au réel : les coefficients
        % cherchés sont réels, donc parties réelle et imaginaire
        % s'empilent.
        x = [real(M); imag(M)] \ [real(v); imag(v)];
        bNouveau = x(1:nb + 1)';
        aNouveau = [1 x(nb + 2:end)'];
        if ~isempty(a) && max(abs([bNouveau aNouveau] - [b a])) < tol
            b = bNouveau;
            a = aNouveau;
            break
        end
        b = bNouveau;
        a = aNouveau;
        reponseA = polyval(fliplr(a), z);
        poidsCourant = wt ./ max(abs(reponseA) .^ 2, eps);
    end
end
