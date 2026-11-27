function angle = ztickangle(varargin)
%ZTICKANGLE Inclinaison des étiquettes de graduation de l'axe des z.
%   ZTICKANGLE(ANGLE) garde l'inclinaison voulue des étiquettes de l'axe
%   des z de l'axe courant, en degrés ; ZTICKANGLE la rend. MatLibre écrit
%   les étiquettes de l'espace horizontalement : l'angle se pose et se
%   relit, sans changer le dessin.
%   ZTICKANGLE(AX, ANGLE) agit sur l'axe AX.
%   A = ZTICKANGLE rend l'inclinaison de l'axe courant.
%
%   Exemple :
%      surf(peaks(20));
%      ztickangle(30);
%      assert(ztickangle == 30);
%
%   Voir aussi xtickangle, zticklabels, zticks.
    reste = varargin;
    if ~isempty(reste) && strcmp(class(reste{1}), 'matlab.graphics.axis.Axes')
        ax = reste{1};
        reste = reste(2:end);
    else
        ax = gca;
    end
    if isempty(reste)
        angle = get(ax, 'ZTickLabelRotation');
        return
    end
    if numel(reste) > 1 || ~isnumeric(reste{1}) || ~isscalar(reste{1}) || ~isfinite(reste{1})
        error('MATLAB:ztickangle:InvalidAngle', 'Angle must be a finite number.');
    end
    set(ax, 'ZTickLabelRotation', double(reste{1}));
    if nargout == 0
        clear angle
    else
        angle = double(reste{1});
    end
end
