function rgb = ntsc2rgb(yiq)
%NTSC2RGB Passage de YIQ à RVB.
%   RGB = NTSC2RGB(YIQ) convertit depuis l'espace de la télévision
%   analogique : Y la luminance, I et Q les deux axes de chrominance.
%
%   Le choix des axes I et Q n'est pas arbitraire : ils sont orientés
%   selon les directions où l'œil discrimine le mieux et le moins bien,
%   ce qui permettait de leur donner des bandes passantes différentes.
%   C'est la même idée que le sous-échantillonnage de la chrominance en
%   numérique, née trente ans plus tôt.
%
%   Le canal Y seul donne une image en niveaux de gris compatible avec un
%   téléviseur noir et blanc : c'est ce qui a permis la transition.
%
%   Exemple :
%      ntsc2rgb([1 0 0])               % blanc : chrominance nulle
%
%   Voir aussi RGB2NTSC, YCBCR2RGB, RGB2GRAY.
    M = [0.299  0.587  0.114
         0.596 -0.274 -0.322
         0.211 -0.523  0.312];
    rgb = appliquerMatriceCouleur(double(yiq), inv(M));
end
