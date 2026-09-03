function suite = zadoffChuSeq(racine, longueur)
%ZADOFFCHUSEQ Suite de Zadoff-Chu.
%   SEQ = ZADOFFCHUSEQ(R,N) rend la suite de Zadoff-Chu de racine R et de
%   longueur N, en colonne :
%
%      seq(m) = exp(-i pi R m (m+1) / N),   m = 0 .. N-1.
%
%   N doit être impair, et R premier avec N.
%
%   Ces suites sont de module constant et d'autocorrélation parfaite :
%   décalée d'un cran, une suite de Zadoff-Chu est orthogonale à
%   elle-même. C'est ce qui en fait le préambule des systèmes cellulaires
%   — on y reconnaît un utilisateur et l'on mesure son retard du même
%   coup.
%
%   Exemple :
%      s = zadoffChuSeq(25, 139);
%      max(abs(abs(s) - 1))           % nul : module constant
%      c = ifft(fft(s) .* conj(fft(s)));
%      abs(c(2)) / abs(c(1))          % négligeable : autocorrélation
%                                     % parfaite
%
%   Voir aussi PSKMOD, RCOSDESIGN, XCORR.
    racine = round(racine);
    longueur = round(longueur);
    if longueur < 1
        error('comm:zadoffChuSeq:Longueur', 'La longueur doit être positive.');
    end
    if mod(longueur, 2) == 0
        error('comm:zadoffChuSeq:Parite', ...
              'La longueur doit être impaire.');
    end
    if racine < 1 || racine >= longueur
        error('comm:zadoffChuSeq:Racine', ...
              'La racine doit rester entre un et %d.', longueur - 1);
    end
    if gcd(racine, longueur) ~= 1
        error('comm:zadoffChuSeq:Premiers', ...
              'La racine et la longueur doivent être premières entre elles.');
    end
    m = (0:(longueur - 1)).';
    suite = exp(-1i * pi * racine * m .* (m + 1) / longueur);
end
