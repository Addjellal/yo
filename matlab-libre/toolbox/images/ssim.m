function [s, carte] = ssim(a, reference, varargin)
%SSIM Indice de similarité structurelle.
%   S = SSIM(A,REF) rend l'indice global, entre -1 et 1 ; 1 signifie que
%   les deux images sont identiques. La fenêtre est une gaussienne de
%   11 points et d'écart-type 1,5, comme dans l'article de Wang et al.
%   et dans MATLAB.
%
%   Exemple :  ssim(x, x)   % 1
    dynamique = 1;
    if isa(a, 'uint8'), dynamique = 255; end
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'DynamicRange')
            dynamique = varargin{k + 1};
        end
    end
    x = double(a);
    y = double(reference);
    c1 = (0.01 * dynamique)^2;
    c2 = (0.03 * dynamique)^2;
    noyau = fspecial('gaussian', 11, 1.5);
    mux = imfilter(x, noyau, 'symmetric');
    muy = imfilter(y, noyau, 'symmetric');
    mux2 = mux.^2;
    muy2 = muy.^2;
    muxy = mux .* muy;
    sigmax2 = imfilter(x.^2, noyau, 'symmetric') - mux2;
    sigmay2 = imfilter(y.^2, noyau, 'symmetric') - muy2;
    sigmaxy = imfilter(x .* y, noyau, 'symmetric') - muxy;
    carte = ((2 * muxy + c1) .* (2 * sigmaxy + c2)) ./ ...
            ((mux2 + muy2 + c1) .* (sigmax2 + sigmay2 + c2));
    s = mean(carte(:));
end
