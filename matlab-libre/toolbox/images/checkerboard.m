function image = checkerboard(n, p, q)
%CHECKERBOARD Damier d'essai pour les transformations géométriques.
%   I = CHECKERBOARD(N,P,Q) rend un damier dont chaque carreau fait N
%   pixels de côté, avec P rangées et Q colonnes de paires de carreaux.
%   La moitié droite est plus claire, ce qui permet de repérer une
%   symétrie.
%
%   Exemple :
%      imshow(checkerboard(10));
    if nargin < 1 || isempty(n), n = 10; end
    if nargin < 2 || isempty(p), p = 4; end
    if nargin < 3 || isempty(q), q = p; end
    carreau = ones(n);
    paire = [zeros(n) carreau; carreau zeros(n)];
    image = repmat(paire, p, q);
    moitie = size(image, 2) / 2;
    droite = image(:, moitie+1:end);
    image(:, moitie+1:end) = droite * 0.7;
end
