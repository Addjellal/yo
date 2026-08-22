function r = zerocrossrate(x)
%ZEROCROSSRATE Proportion de changements de signe.
    x = x(:);
    r = sum(abs(diff(sign(x))) > 0) / max(numel(x) - 1, 1);
end
