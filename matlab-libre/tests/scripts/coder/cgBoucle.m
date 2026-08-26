function s = cgBoucle(v)
%CGBOUCLE Somme des carres, calculee en boucle indexee.
    s = 0;
    for k = 1:numel(v)
        s = s + v(k)^2;
    end
end
