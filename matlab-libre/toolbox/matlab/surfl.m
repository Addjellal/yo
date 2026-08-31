function H = surfl(varargin)
%SURFL Surface éclairée.
%   SURFL(X,Y,Z) trace la surface en la colorant d'après l'angle que fait
%   sa normale avec une source de lumière, ce qui en fait ressortir le
%   relief. SURFL(Z) prend une grille entière.
%
%   SURFL(...,S) place la source dans la direction S = [AZIMUT ELEVATION]
%   ou S = [SX SY SZ].
%
%   H = SURFL(...) rend la poignée.
%
%   MatLibre ne fait pas d'éclairage : la surface est montrée en
%   couleurs, comme SURF, et la direction de la source est acceptée sans
%   effet. Ce qui manque est l'ombrage ; ce que la surface vaut se lit
%   toujours.
%
%   Exemples :
%      surfl(peaks(40));
%      surfl(peaks(40), [45 30]);
%
%   Voir aussi SURF, SURFNORM, LIGHT, LIGHTING, MATERIAL, SHADING.
    entrees = varargin;
    % La direction de la source, en dernier : deux ou trois nombres.
    if numel(entrees) >= 2 && isnumeric(entrees{end}) && ...
       (numel(entrees{end}) == 2 || numel(entrees{end}) == 3) && ...
       ~isequal(size(entrees{end}), size(entrees{1}))
        entrees = entrees(1:end - 1);
    end
    H = surf(entrees{:});
    if nargout == 0
        clear H;
    end
end
