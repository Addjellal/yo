function [stable, alpha] = popov(G, secteur)
%POPOV Critère de Popov de stabilité absolue.
%   OK = POPOV(G,[0 K]) dit si la boucle formée du modèle linéaire G et
%   d'une non-linéarité sans mémoire du secteur [0,K] est absolument
%   stable, c'est-à-dire stable pour toute non-linéarité de ce secteur.
%
%   Le critère demande qu'il existe un nombre ALPHA positif tel que, pour
%   toute pulsation,
%
%      Re[(1 + j*alpha*w) G(jw)] + 1/K  >  0
%
%   Géométriquement : le lieu de Popov — la partie réelle de G(jw) en
%   abscisse, w fois sa partie imaginaire en ordonnée — doit rester à
%   droite d'une droite de pente 1/ALPHA passant par -1/K.
%
%   [OK,ALPHA] = POPOV(...) rend le ALPHA trouvé, ou NaN s'il n'y en a
%   pas.
%
%   Le critère de Popov est moins exigeant que celui du cercle : il
%   suppose la non-linéarité sans mémoire, et gagne à cela d'être
%   applicable là où le critère du cercle échoue.
%
%   Exemples :
%      G = ss(tf(1, [1 2 1]));
%      [ok, alpha] = popov(G, [0 10])
%
%      % Une boucle que le critere refuse : le gain statique est negatif,
%      % et aucune droite ne separe le lieu du point -1/K
%      popov(ss(tf(-1, [1 1])), [0 10])
%
%   Voir aussi SECTF, NYQUIST, HINFNORM, DISKMARGIN.
    G = ss(G);
    K = secteur(2);
    if K <= 0
        stable = true;
        alpha = 0;
        return;
    end
    if ~isempty(G.A) && max(real(eig(G.A))) >= 0
        stable = false;
        alpha = NaN;
        return;
    end
    w = logspace(-4, 4, 2000);
    H = freqresp(G, w);
    valeurs = zeros(1, numel(w));
    for k = 1:numel(w)
        if ndims(H) == 3
            valeurs(k) = H(1, 1, k);
        else
            valeurs(k) = H(k);
        end
    end
    partieReelle = real(valeurs);
    partieImaginaire = imag(valeurs) .* w;
    % On cherche un alpha positif qui laisse la droite a gauche du lieu.
    for alphaEssai = [0, 10 .^ (-4:0.1:4)]
        if all(partieReelle - alphaEssai * partieImaginaire + 1 / K > 0)
            stable = true;
            alpha = alphaEssai;
            return;
        end
    end
    stable = false;
    alpha = NaN;
end
