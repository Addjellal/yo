function s = cgCollision(A, B, t0)
%CGCOLLISION Variables nommees comme les identifiants produits par le
%   traducteur : k, i, j, p, s, t0. Le C doit rester correct — la plage
%   litterale et les boucles produites ne doivent pas capturer le k MATLAB.
    s = A * B;
    for k = 1:2
        v = ones(1, 2) * k;
        w = 2:2:8;
        i = v(1) + t0;
        j = v(2) * 2;
        p = i + j + w(k);
        s(k) = s(k) + p;
    end
end
