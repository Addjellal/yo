function [reel, imaginaire, w] = nyquist(sys, w)
%NYQUIST Lieu de Nyquist.
    if nargin < 2
        [m, p, w] = bode(sys);
    else
        [m, p, w] = bode(sys, w);
    end
    h = m .* exp(1i * p * pi / 180);
    reel = real(h);
    imaginaire = imag(h);
    if nargout == 0
        plot(reel, imaginaire, reel, -imaginaire);
        grid on;
        xlabel('Partie réelle');
        ylabel('Partie imaginaire');
        title('Lieu de Nyquist');
    end
end
