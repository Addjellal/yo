function tf = isstable(b, a)
%ISSTABLE Le filtre est-il stable ?
%   Un filtre numérique est stable si tous ses pôles sont strictement à
%   l'intérieur du cercle unité.
%
%   ISSTABLE(SOS) accepte aussi une matrice de sections du second ordre.
%
%   ISSTABLE(SYS) accepte un modèle linéaire : la stabilité s'y lit sur
%   les pôles, strictement à gauche de l'axe imaginaire pour un modèle
%   continu, strictement dans le cercle unité pour un modèle discret.
    if nargin < 2 && isstruct(b) && isfield(b, 'type')
        % Modèle linéaire de la Control System Toolbox : la stabilité se
        % lit sur les pôles, à gauche de l'axe imaginaire en continu, dans
        % le cercle unité en discret.
        p = pole(b);
        if b.Ts == 0
            tf = all(real(p) < 0);
        else
            tf = all(abs(p) < 1);
        end
        return
    end
    if nargin < 2
        if size(b, 2) == 6 && size(b, 1) >= 1
            tf = true;
            for section = 1:size(b, 1)
                tf = tf && isstable(1, b(section, 4:6));
            end
            return
        end
        a = b;
        b = 1;                    %#ok<NASGU>
    end
    a = double(a(:)).';
    while numel(a) > 1 && a(1) == 0
        a(1) = [];
    end
    if numel(a) <= 1
        tf = true;
        return
    end
    tf = all(abs(roots(a)) < 1);
end
