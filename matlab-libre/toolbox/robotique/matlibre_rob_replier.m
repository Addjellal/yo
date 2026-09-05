function d = matlibre_rob_replier(d)
%MATLIBRE_ROB_REPLIER Angles ramenés dans [-pi, pi].
%   La formule mod(d + pi, 2 pi) - pi replie tout angle dans
%   l'intervalle, et le cas exact de pi est rendu à pi plutôt qu'à -pi :
%   c'est la convention de MATLAB.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    d = mod(d + pi, 2 * pi) - pi;
    d(d == -pi) = pi;
end
