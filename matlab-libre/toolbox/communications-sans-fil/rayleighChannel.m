function [y, h] = rayleighChannel(x, nTrajets)
%RAYLEIGHCHANNEL Canal à évanouissements de Rayleigh.
    if nargin < 2
        nTrajets = 1;
    end
    h = (randn(nTrajets, 1) + 1i * randn(nTrajets, 1)) / sqrt(2 * nTrajets);
    y = conv(x(:), h);
    y = y(1:numel(x));
end
