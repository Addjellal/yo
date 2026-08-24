function [p, z] = pzmap(sys)
%PZMAP Pôles et zéros d'un modèle.
%   [P,Z] = PZMAP(SYS) rend les pôles et les zéros en colonnes. Sans
%   sortie, la fonction les place dans le plan complexe : les pôles par
%   des croix, les zéros par des ronds.
%
%   Exemple :
%      [p, z] = pzmap(tf([1 1], [1 3 2]));   % p = [-2;-1], z = -1
%
%   Voir aussi POLE, ZERO, DAMP, RLOCUS.
    p = pole(sys);
    z = zero(sys);
    p = p(:);
    z = z(:);
    if nargout == 0
        plot(real(p), imag(p), 'x', real(z), imag(z), 'o');
        grid on;
        xlabel('Partie réelle');
        ylabel('Partie imaginaire');
        title('Carte des pôles et des zéros');
        clear p z
    end
end
