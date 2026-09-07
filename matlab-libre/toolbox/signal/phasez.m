function [phi, w] = phasez(b, a, n)
%PHASEZ Réponse en phase déroulée d'un filtre numérique.
%   [PHI,W] = PHASEZ(B,A,N) rend la phase continue sur N points entre 0
%   et pi, comme FREQZ pour le module.
%
%   Exemple :
%      [b, a] = butter(4, 0.3);
%      [phi, w] = phasez(b, a, 128);
%      abs(phi(1)) < 1e-12         % la phase est nulle au continu
    if nargin < 2 || isempty(a), a = 1; end
    if nargin < 3, n = 512; end
    [h, w] = freqz(b, a, n);
    phi = unwrap(angle(h));
    phi = phi(:);
    w = w(:);
end
