function angle = ytickangle(varargin)
%YTICKANGLE Incline les étiquettes de graduation des ordonnées.
%   YTICKANGLE(ANGLE) incline les étiquettes de l'axe courant de ANGLE
%   degrés, dans le sens trigonométrique, chacune se terminant sur sa
%   graduation.
%   YTICKANGLE(AX, ANGLE) agit sur l'axe AX.
%   A = YTICKANGLE rend l'inclinaison de l'axe courant.
%
%   Exemple :
%      plot(1:4);
%      ytickangle(30);
%      assert(ytickangle == 30);
%
%   Voir aussi xtickangle, yticklabels, yticks.
    reste = varargin;
    if ~isempty(reste) && strcmp(class(reste{1}), 'matlab.graphics.axis.Axes')
        ax = reste{1};
        reste = reste(2:end);
    else
        ax = gca;
    end
    if isempty(reste)
        angle = get(ax, 'YTickLabelRotation');
        return
    end
    if numel(reste) > 1 || ~isnumeric(reste{1}) || ~isscalar(reste{1}) || ~isfinite(reste{1})
        error('MATLAB:ytickangle:InvalidAngle', 'L''angle doit être un nombre fini.');
    end
    set(ax, 'YTickLabelRotation', double(reste{1}));
    if nargout == 0
        clear angle
    else
        angle = double(reste{1});
    end
end
