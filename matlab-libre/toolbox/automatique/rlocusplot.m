function rlocusplot(varargin)
%RLOCUSPLOT Lieu des racines.
%   RLOCUSPLOT(SYS) trace le lieu des racines. C'est RLOCUS, sous le nom
%   que MATLAB donne à la version qui rend une poignée de tracé.
%
%   Exemples :
%      figure
%      rlocusplot(tf(1, [1 2 0]));
%      close
%
%   Voir aussi RLOCUS, PZMAP, SGRID, POLE.
    rlocus(varargin{:});
end
