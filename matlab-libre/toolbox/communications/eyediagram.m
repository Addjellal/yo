function segments = eyediagram(x, n)
%EYEDIAGRAM Découpe un signal en segments de N échantillons.
%   SEGMENTS = EYEDIAGRAM(X,N) rend une matrice dont chaque ligne est une
%   trace ; sans sortie, la fonction les trace superposées.
    x = x(:).';
    m = floor(numel(x) / n);
    segments = reshape(x(1:m*n), n, m).';
    if nargout == 0
        hold on;
        for k = 1:m
            plot(1:n, segments(k, :));
        end
        hold off;
        title('Diagramme de l''oeil');
    end
end
