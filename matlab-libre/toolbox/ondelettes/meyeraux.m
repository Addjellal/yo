function y = meyeraux(x)
%MEYERAUX Fonction auxiliaire de l'ondelette de Meyer.
%   Y = MEYERAUX(X) évalue
%
%      nu(x) = 35 x^4 - 84 x^5 + 70 x^6 - 20 x^7.
%
%   C'est le polynôme de plus bas degré qui vaut zéro en zéro, un en un,
%   et dont les trois premières dérivées s'annulent aux deux bouts. Il
%   sert de transition douce dans la fenêtre de Meyer : c'est cette
%   platitude qui donne à l'ondelette sa décroissance rapide.
%
%   La fonction complémentaire vérifie nu(x) + nu(1-x) = 1, ce qui fait
%   de la fenêtre une partition de l'unité.
%
%   Exemple :
%      meyeraux(0)                    % 0
%      meyeraux(1)                    % 1
%      meyeraux(0.5) + meyeraux(0.5)  % 1
%
%   Voir aussi MEYER, MORLET, MEXIHAT.
    x = double(x);
    y = 35 * x .^ 4 - 84 * x .^ 5 + 70 * x .^ 6 - 20 * x .^ 7;
end
