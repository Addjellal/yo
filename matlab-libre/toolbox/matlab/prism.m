function carte = prism(m)
%PRISM Carte de couleurs répétant les six couleurs du prisme.
    if nargin < 1 || isempty(m), m = 256; end
    m = round(m);
    base = [1 0 0; 1 0.5 0; 1 1 0; 0 1 0; 0 0 1; 0.6667 0 1];
    indices = mod(0:m-1, 6) + 1;
    carte = base(indices, :);
end
