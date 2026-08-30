function [p, z] = pzmap(varargin)
%PZMAP Pôles et zéros d'un modèle.
%   PZMAP(SYS) place les pôles et les zéros du modèle dans le plan
%   complexe : les pôles par des croix, les zéros par des ronds. La
%   stabilité se lit à la position des croix — à gauche de l'axe
%   imaginaire en temps continu, dans le cercle unité en discret.
%
%   PZMAP(SYS1,SYS2,...) superpose plusieurs modèles.
%
%   [P,Z] = PZMAP(SYS) ne trace rien et rend les pôles et les zéros en
%   colonnes.
%
%   Exemple :
%      [p, z] = pzmap(tf([1 1], [1 3 2]));   % p = [-2;-1], z = -1
%
%   Voir aussi POLE, ZERO, DAMP, RLOCUS.
    [modeles, styles] = matlibre_arguments_lti(varargin);
    if isempty(modeles)
        error('MATLAB:minrhs', 'Not enough input arguments.');
    end
    if nargout > 0
        if numel(modeles) > 1
            error('Control:analysis:MultipleModels', ...
                  ['The command PZMAP(SYS1,SYS2,...) with output arguments ' ...
                   'is not supported.']);
        end
        p = pole(modeles{1});
        z = zero(modeles{1});
        p = p(:);
        z = z(:);
        return;
    end
    courbes = {};
    for k = 1:numel(modeles)
        pk = pole(modeles{k});
        zk = zero(modeles{k});
        courbes{end+1} = real(pk(:));                       %#ok<AGROW>
        courbes{end+1} = imag(pk(:));                       %#ok<AGROW>
        if isempty(styles{k})
            courbes{end+1} = 'x';                           %#ok<AGROW>
        else
            courbes{end+1} = [styles{k} 'x'];               %#ok<AGROW>
        end
        if ~isempty(zk)
            courbes{end+1} = real(zk(:));                   %#ok<AGROW>
            courbes{end+1} = imag(zk(:));                   %#ok<AGROW>
            if isempty(styles{k})
                courbes{end+1} = 'o';                       %#ok<AGROW>
            else
                courbes{end+1} = [styles{k} 'o'];           %#ok<AGROW>
            end
        end
    end
    plot(courbes{:});
    grid on;
    xlabel('Partie réelle');
    ylabel('Partie imaginaire');
    title('Carte des pôles et des zéros');
end
