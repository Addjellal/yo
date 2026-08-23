function r = hsv2rgb(h, s, v)
%HSV2RGB Teinte, saturation, valeur vers RVB.
%   R = HSV2RGB(IMAGE) où IMAGE est MxNx3.
    if nargin == 3
        image = cat(3, h, s, v);
    else
        image = h;
    end
    H = image(:, :, 1) * 6;
    S = image(:, :, 2);
    V = image(:, :, 3);
    secteur = floor(H);
    f = H - secteur;
    p = V .* (1 - S);
    q = V .* (1 - S .* f);
    t = V .* (1 - S .* (1 - f));
    secteur = mod(secteur, 6);
    R = zeros(size(V)); G = zeros(size(V)); B = zeros(size(V));
    for k = 0:5
        m = secteur == k;
        switch k
            case 0, R(m) = V(m); G(m) = t(m); B(m) = p(m);
            case 1, R(m) = q(m); G(m) = V(m); B(m) = p(m);
            case 2, R(m) = p(m); G(m) = V(m); B(m) = t(m);
            case 3, R(m) = p(m); G(m) = q(m); B(m) = V(m);
            case 4, R(m) = t(m); G(m) = p(m); B(m) = V(m);
            case 5, R(m) = V(m); G(m) = p(m); B(m) = q(m);
        end
    end
    r = cat(3, R, G, B);
end
