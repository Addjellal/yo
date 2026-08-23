function tf = isstable(b, a)
%ISSTABLE Le filtre est-il stable ?
%   Un filtre numérique est stable si tous ses pôles sont strictement à
%   l'intérieur du cercle unité.
%
%   ISSTABLE(SOS) accepte aussi une matrice de sections du second ordre.
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
