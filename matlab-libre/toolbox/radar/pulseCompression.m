function [y, retards] = pulseCompression(recu, impulsion)
%PULSECOMPRESSION Compression d'impulsion et position du maximum.
    y = matchedFilter(recu, impulsion);
    retards = (1:numel(y)) - numel(impulsion);
end
