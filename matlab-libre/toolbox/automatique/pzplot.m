function pzplot(varargin)
%PZPLOT Carte des pôles et des zéros.
%   PZPLOT(SYS) trace les pôles et les zéros dans le plan complexe. C'est
%   PZMAP, sous le nom que MATLAB donne à la version qui rend une poignée
%   de tracé ; les deux dessinent la même chose.
%
%   PZPLOT(SYS1,SYS2,...) superpose plusieurs modèles.
%
%   Exemples :
%      figure
%      pzplot(tf([1 1], [1 3 2]));
%      close
%
%   Voir aussi PZMAP, POLE, ZERO, RLOCUS, SGRID.
    pzmap(varargin{:});
end
