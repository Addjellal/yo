function y = defuzz(x, mf, methode)
%DEFUZZ Défuzzification d'un ensemble flou.
%   Y = DEFUZZ(X,MF,'centroid'|'bisector'|'mom'|'som'|'lom')
    if nargin < 3
        methode = 'centroid';
    end
    switch lower(char(methode))
        case 'centroid'
            d = sum(mf);
            if d == 0
                y = mean(x);
            else
                y = sum(x .* mf) / d;
            end
        case 'mom'
            m = max(mf);
            y = mean(x(mf == m));
        case 'som'
            m = max(mf);
            candidats = x(mf == m);
            y = candidats(1);
        case 'lom'
            m = max(mf);
            candidats = x(mf == m);
            y = candidats(end);
        otherwise
            cumule = cumsum(mf);
            moitie = cumule(end) / 2;
            indice = find(cumule >= moitie, 1);
            y = x(indice);
    end
end
