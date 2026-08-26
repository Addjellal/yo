function rgb = ntsc2rgb(yiq)
%NTSC2RGB Passage de YIQ à RVB.
    M = [0.299  0.587  0.114
         0.596 -0.274 -0.322
         0.211 -0.523  0.312];
    rgb = appliquerMatriceCouleur(double(yiq), inv(M));
end
