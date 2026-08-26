function carte = flag(m)
%FLAG Carte de couleurs alternant rouge, blanc, bleu et noir.
%   Utile pour faire ressortir les lignes de niveau : deux valeurs
%   voisines y prennent des couleurs très différentes.
    if nargin < 1 || isempty(m), m = 256; end
    m = round(m);
    base = [1 0 0; 1 1 1; 0 0 1; 0 0 0];
    indices = mod(0:m-1, 4) + 1;
    carte = base(indices, :);
end
