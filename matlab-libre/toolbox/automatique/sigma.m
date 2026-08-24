function [valeurs, w] = sigma(sys, w)
%SIGMA Valeurs singulières de la réponse fréquentielle.
%   SV = SIGMA(SYS,W) rend, pour chaque pulsation, les valeurs
%   singulières de la matrice de transfert, rangées par ligne et
%   décroissantes. Pour un modèle monovariable, il n'y en a qu'une, égale
%   au module de la réponse : c'est le diagramme de gain.
%
%   [SV,W] = SIGMA(SYS) choisit lui-même la grille de pulsations.
%
%   Sans sortie, la fonction trace les valeurs singulières en décibels.
%
%   Exemple :
%      max(sigma(tf(1, [1 1])))   % 1 : le gain le plus fort est en zéro
%
%   Voir aussi FREQRESP, BODE, HINFNORM.
    if nargin < 2 || isempty(w)
        [~, ~, w] = bode(sys);
    end
    w = w(:);
    if strcmp(sys.type, 'ss') && ~issiso(sys)
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
    if nargout == 0
        semilogx(w, 20 * log10(valeurs.'));
        grid on;
        xlabel('Pulsation (rad/s)');
        ylabel('Valeurs singulières (dB)');
        title('Diagramme des valeurs singulières');
        clear valeurs
    end
end
