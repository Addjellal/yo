function y = im2double(x)
%IM2DOUBLE Convertit une image en double dans [0,1].
%   Y = IM2DOUBLE(X) ramène une image entière sur l'intervalle [0,1] en
%   divisant par la valeur maximale de son type — 255 pour uint8, 65535
%   pour uint16. Une image déjà flottante est rendue telle quelle.
%
%   Toute la boîte à outils travaille en flottant : c'est ce qui évite les
%   dépassements et les troncatures au milieu d'un calcul. IM2UINT8 refait
%   le chemin inverse au moment d'écrire.
%
%   Exemple :
%      im2double(uint8([0 128 255]))   % [0 0.502 1]
%      im2double([0.2 0.8])            % inchange
%
%   Voir aussi IM2UINT8, MAT2GRAY, IMREAD.
    if isa(x, 'uint8')
        y = double(x) / 255;
    elseif isa(x, 'uint16')
        y = double(x) / 65535;
    elseif islogical(x)
        y = double(x);
    else
        y = double(x);
    end
end
