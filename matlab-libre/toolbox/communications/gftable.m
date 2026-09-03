function table = gftable(m, prim, p)
%GFTABLE Table d'un corps de Galois d'extension.
%   T = GFTABLE(M) rend la table de GF(2^M) : une ligne par élément, dans
%   l'ordre des exposants. La ligne K donne les coefficients du polynôme
%   qui représente x^(K-2), par puissances croissantes ; la première
%   ligne est l'élément nul.
%
%   T = GFTABLE(M,PRIM) emploie le polynôme primitif donné,
%   GFTABLE(M,PRIM,P) travaille sur GF(P^M).
%
%   C'est la table qui rend l'arithmétique du corps praticable :
%   multiplier revient à additionner des exposants, et additionner à
%   ajouter les polynômes lus dans la table. MATLAB range la sienne dans
%   un fichier ; MatLibre la rend, ce qui évite un état caché.
%
%   Exemple :
%      t = gftable(3);
%      size(t)                        % 8x3 : huit éléments de GF(8)
%      t(2, :)                        % [1 0 0] : l'élément un
%
%   Voir aussi GFPRIMDF, GFCOSETS, GFROOTS, GFADD.
    if nargin < 3 || isempty(p), p = 2; end
    if nargin < 2 || isempty(prim), prim = gfprimdf(m, p); end
    exigerPremier(p, 'gftable');
    m = round(m);
    prim = mod(double(gftrunc(prim(:).')), p);
    if numel(prim) - 1 ~= m
        error('comm:gftable:Degre', ...
              'Le polynôme primitif doit être de degré %d.', m);
    end
    if gfprimck(prim, p) ~= 1
        error('comm:gftable:Primitif', ...
              'Le polynôme donné n''est pas primitif.');
    end
    nombre = p ^ m;
    table = zeros(nombre, m);
    % La première ligne est zéro ; la suivante est un ; chacune se déduit
    % de la précédente en multipliant par x, puis en réduisant modulo le
    % polynôme primitif.
    courant = [1, zeros(1, m - 1)];
    for k = 2:nombre
        table(k, :) = courant;
        decale = [0, courant];
        [~, reste] = gfdeconv(decale, prim, p);
        courant = completerLongueur(gftrunc(reste), m);
    end
end
