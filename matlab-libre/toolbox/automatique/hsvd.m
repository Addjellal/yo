function g = hsvd(sys)
%HSVD Valeurs singulières de Hankel d'un modèle stable.
%   G = HSVD(SYS) rend, par ordre décroissant, les racines carrées des
%   valeurs propres du produit des deux grammiens :
%
%      g = sqrt(eig(Wc * Wo))
%
%   Chaque valeur mesure ce qu'un état apporte à la relation entrée-sortie :
%   celles qui sont petites désignent les états qu'on peut retirer sans
%   changer sensiblement la réponse. C'est sur elles que reposent BALRED
%   et MODRED.
%
%   Exemple :
%      hsvd(ss(-1, 1, 1, 0))   % 0.5
%
%   Voir aussi BALREAL, BALRED, MODRED, GRAM.
    s = ss(sys);
    if isempty(s.A)
        g = zeros(0, 1);
        return
    end
    if ~isstable(s)
        error('control:hsvd:Unstable', ...
              'Les grammiens ne convergent que pour un modèle stable.');
    end
    Wc = gram(s, 'c');
    Wo = gram(s, 'o');
    valeurs = eig(Wc * Wo);
    g = sort(sqrt(abs(real(valeurs))), 'descend');
    g = g(:);
end
