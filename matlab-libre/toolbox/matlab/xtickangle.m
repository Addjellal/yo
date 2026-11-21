function angle = xtickangle(varargin)
%XTICKANGLE Incline les étiquettes de graduation des abscisses.
%   XTICKANGLE(ANGLE) incline les étiquettes de l'axe courant de ANGLE
%   degrés, dans le sens trigonométrique : 45 les fait monter vers la
%   droite, chacune se terminant sur sa graduation, 90 les écrit de bas en
%   haut. La marge du bas s'agrandit pour qu'elles tiennent.
%   XTICKANGLE(AX, ANGLE) agit sur l'axe AX.
%   A = XTICKANGLE rend l'inclinaison de l'axe courant.
%
%   Exemple :
%      bar([3 5 2 4]);
%      xticklabels({'janvier', 'fevrier', 'mars', 'avril'});
%      xtickangle(45);
%      assert(xtickangle == 45);
%
%   Voir aussi ytickangle, xticklabels, xticks.
    reste = varargin;
    if ~isempty(reste) && strcmp(class(reste{1}), 'matlab.graphics.axis.Axes')
        ax = reste{1};
        reste = reste(2:end);
    else
        ax = gca;
    end
    if isempty(reste)
        angle = get(ax, 'XTickLabelRotation');
        return
    end
    if numel(reste) > 1 || ~isnumeric(reste{1}) || ~isscalar(reste{1}) || ~isfinite(reste{1})
        error('MATLAB:xtickangle:InvalidAngle', 'L''angle doit être un nombre fini.');
    end
    set(ax, 'XTickLabelRotation', double(reste{1}));
    if nargout == 0
        clear angle
    else
        angle = double(reste{1});
    end
end
