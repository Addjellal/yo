function h = newplot()
%NEWPLOT Prépare l'axe courant à recevoir un nouveau tracé.
%   H = NEWPLOT rend l'axe courant après l'avoir effacé, sauf si HOLD est
%   actif — auquel cas il le rend tel quel. C'est ce que fait toute
%   fonction de tracé avant de dessiner ; on l'appelle quand on en écrit
%   une soi-même, pour qu'elle respecte HOLD comme les autres.
%
%   Exemple :
%      function monTrace(x, y)
%          newplot;
%          line(x, y);
%          line(x, -y);
%      end
%
%   Voir aussi HOLD, CLA, GCA, CLF, LINE.
    if ~ishold()
        cla;
    end
    h = gca();
    if nargout == 0
        clear h;
    end
end
