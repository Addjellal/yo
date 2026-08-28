function y = cgComplexeReel(x)
%CGCOMPLEXEREEL Range un complexe dans un vecteur reel : le traducteur refuse.
    y = zeros(1, 2);
    y(1) = x + 1i;
    y(2) = x;
end
