function zplane(b, a)
%ZPLANE Trace les zéros et les pôles dans le plan complexe.
%   ZPLANE(B,A) à partir des coefficients, ZPLANE(Z,P) à partir des zéros
%   et des pôles. Le cercle unité sert de repère.
    if nargin < 2, a = 1; end
    if numel(b) > 1 && numel(a) > 1 && ~isreal(b(:)') || iscolumn(b)
        z = b; p = a;
    else
        [z, p] = tf2zp(b, a);
    end
    theta = linspace(0, 2 * pi, 200);
    plot(cos(theta), sin(theta), 'k:');
    hold on;
    if ~isempty(z), plot(real(z), imag(z), 'o'); end
    if ~isempty(p), plot(real(p), imag(p), 'x'); end
    hold off;
    axis equal;
    grid on;
    xlabel('Partie reelle');
    ylabel('Partie imaginaire');
end
