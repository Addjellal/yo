function H = fplot3(fx, fy, fz, intervalle, varargin)
%FPLOT3 Courbe paramétrée de l'espace.
%   FPLOT3(FX,FY,FZ) trace la courbe (FX(t),FY(t),FZ(t)) pour t allant de
%   -5 à 5. Les trois arguments sont des poignées d'une variable.
%   FPLOT3(FX,FY,FZ,[A B]) emploie l'intervalle donné.
%   FPLOT3(...,OPTIONS) passe les options de tracé à PLOT3.
%
%   H = FPLOT3(...) rend la poignée.
%
%   L'échantillonnage est régulier en paramètre, non en longueur d'arc :
%   une courbe qui accélère est donc moins finement décrite là où elle va
%   vite. Serrer l'intervalle est le remède.
%
%   Exemple :
%      fplot3(@(t) sin(t), @(t) cos(t), @(t) t, [0 6*pi]);   % une helice
%
%   Voir aussi FPLOT, PLOT3, FSURF, FIMPLICIT3.
    if nargin < 4 || isempty(intervalle)
        intervalle = [-5 5];
    end
    t = linspace(intervalle(1), intervalle(2), 400);
    x = matlibre_evaluer_courbe(fx, t);
    y = matlibre_evaluer_courbe(fy, t);
    z = matlibre_evaluer_courbe(fz, t);
    H = plot3(x, y, z, varargin{:});
    if nargout == 0
        clear H;
    end
end
