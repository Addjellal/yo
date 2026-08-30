function [valeurs, w] = sigma(varargin)
%SIGMA Valeurs singulières de la réponse fréquentielle.
%   SIGMA(SYS) trace, en décibels et en échelle logarithmique de
%   pulsation, les valeurs singulières de la matrice de transfert. Pour un
%   modèle monovariable il n'y en a qu'une, égale au module de la réponse :
%   le tracé est alors celui de BODEMAG.
%
%   SIGMA(SYS,W) impose la grille de pulsations, en radians par seconde :
%   un vecteur, ou {WMIN,WMAX} pour n'en donner que les bornes.
%
%   SIGMA(SYS1,SYS2,...,W) superpose plusieurs modèles ; une chaîne de
%   style peut suivre chacun d'eux, comme dans PLOT :
%   SIGMA(S,'b',T,'r--',W).
%
%   SV = SIGMA(SYS,W) ne trace rien et rend les valeurs singulières,
%   rangées par ligne et décroissantes, une colonne par pulsation.
%   [SV,W] = SIGMA(SYS) rend en plus la grille employée.
%
%   La plus grande valeur singulière est le gain que le modèle peut donner
%   à cette pulsation ; son maximum sur toutes les pulsations est la norme
%   H-infini, que rend HINFNORM.
%
%   Exemple :
%      max(sigma(tf(1, [1 1])))   % 1 : le gain le plus fort est en zéro
%
%   Voir aussi FREQRESP, BODE, BODEMAG, HINFNORM.
    [modeles, styles, w] = matlibre_arguments_lti(varargin);
    if isempty(modeles)
        error('MATLAB:minrhs', 'Not enough input arguments.');
    end
    if nargout > 0
        if numel(modeles) > 1
            error('Control:analysis:MultipleModels', ...
                  ['The command SIGMA(SYS1,SYS2,...) with output arguments ' ...
                   'is not supported.']);
        end
        [valeurs, w] = valeursSingulieres(modeles{1}, w);
        return;
    end
    courbes = {};
    for k = 1:numel(modeles)
        [sv, wk] = valeursSingulieres(modeles{k}, w);
        courbes{end+1} = wk;                    %#ok<AGROW>
        courbes{end+1} = 20 * log10(sv.');      %#ok<AGROW>
        if ~isempty(styles{k})
            courbes{end+1} = styles{k};         %#ok<AGROW>
        end
    end
    semilogx(courbes{:});
    grid on;
    xlabel('Pulsation (rad/s)');
    ylabel('Valeurs singulières (dB)');
    title('Diagramme des valeurs singulières');
end

function [valeurs, w] = valeursSingulieres(sys, w)
%VALEURSSINGULIERES Valeurs singulières d'un modèle sur une grille.
    if isempty(w)
        w = matlibre_pulsations(sys);
    end
    w = w(:);
    if strcmp(class(sys), 'ss') && ~issiso(sys)
        ny = size(sys.C, 1);
        nu = size(sys.B, 2);
        n = size(sys.A, 1);
        if sys.Ts > 0
            points = exp(1i * w * sys.Ts);
        else
            points = 1i * w;
        end
        valeurs = zeros(min(ny, nu), numel(w));
        for k = 1:numel(w)
            valeurs(:, k) = svd(sys.C * ((points(k) * eye(n) - sys.A) \ sys.B) + sys.D);
        end
    else
        valeurs = abs(freqresp(sys, w));
        valeurs = valeurs(:).';
    end
end
