function modele = polyest(donnees, ordres, varargin)
%POLYEST Estimation d'un modèle polynomial quelconque.
%   M = POLYEST(Z,[na nb nc nd nf nk]) ajuste
%
%      A(q) y(t) = [B(q)/F(q)] u(t-nk) + [C(q)/D(q)] e(t)
%
%   en minimisant la somme des carrés de l'erreur de prédiction à un pas.
%   Toutes les familles usuelles en sont des cas particuliers, et ARX,
%   ARMAX, OE et BJ ne font qu'appeler POLYEST avec les ordres qui les
%   définissent.
%
%   Sauf pour ARX, le critère n'est pas quadratique en les paramètres : il
%   a plusieurs minimums, et la descente trouve celui dont elle part. Le
%   point de départ est donc tiré d'une estimation ARX préalable, qui, elle,
%   est exacte — et non d'un tirage au sort.
%
%   Options : 'MaxIter' (200) et 'Tolerance' (1e-10).
%
%   Exemple :
%      m = polyest(z, [2 2 1 0 0 1]);      % un ARMAX
%
%   Voir aussi ARX, ARMAX, OE, BJ, PEM, IDPOLY.
    ordres = matlibre_id_ordres(ordres, [0 0 0 0 0 1]);
    modele = matlibre_id_estimer(donnees, ordres, 'polyest', varargin);
end
