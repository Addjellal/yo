function datetick(axe, format_, varargin)
%DATETICK Gradue un axe en dates.
%   DATETICK remplace les graduations de l'axe des abscisses par les
%   dates correspondantes, les valeurs étant lues comme des numéros de
%   série DATENUM.
%
%   DATETICK(AXE) gradue l'axe nommé : 'x', 'y' ou 'z'.
%   DATETICK(AXE,FORMAT) emploie le format donné, qui peut être un numéro
%   de format de DATESTR ou une chaîne comme 'yyyy-mm-dd'.
%
%   DATETICK(...,'keeplimits') ne change pas les bornes de l'axe ;
%   'keepticks' garde les graduations en place et n'en réécrit que les
%   étiquettes.
%
%   Exemples :
%      t = datenum(2024, 1, 1) + (0:29);
%      plot(t, cumsum(randn(1, 30)));
%      datetick('x', 'dd/mm');
%
%   Voir aussi DATENUM, DATESTR, XTICKS, XTICKLABELS, DATETIME.
    if nargin < 1 || isempty(axe)
        axe = 'x';
    end
    if nargin < 2 || isempty(format_)
        format_ = 'dd-mmm-yyyy';
    end
    axe = lower(char(axe));
    if strcmp(axe, 'y')
        bornes = ylim();
    else
        bornes = xlim();
    end
    garderGraduations = false;
    for k = 1:numel(varargin)
        if strcmpi(char(varargin{k}), 'keepticks')
            garderGraduations = true;
        end
    end
    if garderGraduations
        if strcmp(axe, 'y')
            positions = yticks();
        else
            positions = xticks();
        end
        if isempty(positions)
            positions = linspace(bornes(1), bornes(2), 6);
        end
    else
        positions = linspace(bornes(1), bornes(2), 6);
    end
    etiquettes = cell(numel(positions), 1);
    for k = 1:numel(positions)
        etiquettes{k} = datestr(positions(k), format_);
    end
    if strcmp(axe, 'y')
        yticks(positions);
        yticklabels(etiquettes);
    else
        xticks(positions);
        xticklabels(etiquettes);
    end
end
