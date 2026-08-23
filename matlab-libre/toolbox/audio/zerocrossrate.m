function r = zerocrossrate(x)
%ZEROCROSSRATE Proportion de passages par zéro.
%   R = ZEROCROSSRATE(X) compte les changements de signe et divise par la
%   longueur de la fenêtre, comme le fait MATLAB.
%
%   Exemple :
%      zerocrossrate([1 -1 1 -1])   % 0.75
    x = x(:);
    signes = sign(x);
    signes(signes == 0) = 1;
    r = sum(signes(2:end) ~= signes(1:end-1)) / numel(x);
end
