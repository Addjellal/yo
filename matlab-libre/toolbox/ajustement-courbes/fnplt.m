function h = fnplt(f, varargin)
%FNPLT Trace une fonction par morceaux.
%   FNPLT(F) trace la spline sur son intervalle de définition.
%   FNPLT(F,STYLE) impose le style du trait.
%   FNPLT(F,[A B]) restreint l'intervalle.
%   H = FNPLT(...) rend la poignée du tracé.
%
%   Exemple :
%      fnplt(spline(1:5, [1 3 2 5 4]));
%
%   Voir aussi FNVAL, PLOT, FNBRK.
    style = '-';
    intervalle = fnbrk(f, 'interval');
    for k = 1:numel(varargin)
        courant = varargin{k};
        if ischar(courant)
            style = courant;
        elseif isnumeric(courant) && numel(courant) == 2
            intervalle = double(courant);
        end
    end
    x = linspace(intervalle(1), intervalle(2), 400).';
    h = plot(x, fnval(f, x), style);
end
