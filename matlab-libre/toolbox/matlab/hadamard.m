function H = hadamard(n)
%HADAMARD Matrice de Hadamard.
%   H = HADAMARD(N) rend une matrice N sur N de plus ou moins un dont les
%   colonnes sont deux à deux orthogonales : H' H vaut N fois l'identité.
%
%   Une telle matrice n'existe que pour N valant 1, 2, ou un multiple de
%   quatre — et l'existence pour tout multiple de quatre reste une
%   conjecture ouverte. La construction employée ici est celle de
%   Sylvester : elle double la taille à chaque étape, si bien qu'elle ne
%   donne que les puissances de deux, ainsi que 12 et 20 par les
%   constructions de Paley qui les complètent.
%
%   Les matrices de Hadamard servent partout où l'on veut des codes
%   orthogonaux : étalement de spectre, plans d'expérience, transformée de
%   Walsh-Hadamard. Leur intérêt tient à ce qu'elles n'emploient que des
%   additions et des soustractions — aucune multiplication.
%
%   La première ligne et la première colonne ne comptent que des uns :
%   c'est la forme normalisée, que la construction de Sylvester donne
%   d'elle-même.
%
%   Exemple :
%      H = hadamard(8);
%      H' * H                          % 8 * eye(8)
%      unique(H(:))                    % -1 et 1, rien d'autre
%
%   Voir aussi FWHT, IFWHT, MAGIC, TOEPLITZ.
    n = double(n);
    if ~isscalar(n) || n < 1 || n ~= round(n)
        error('MATLAB:hadamard:Ordre', ...
              'N doit etre un entier positif.');
    end
    if n == 1
        H = 1;
        return
    end
    % La construction de Sylvester part d'un noyau et double : le noyau
    % vaut 1, 2 ou 12, selon ce qui divise N.
    for noyau = [1 2 12 20]
        reste = n / noyau;
        if reste >= 1 && reste == round(reste) && ...
                abs(log2(reste) - round(log2(reste))) < 1e-12
            H = matlibre_hadamard_noyau(noyau);
            for k = 1:round(log2(reste))
                H = [H, H; H, -H];
            end
            return
        end
    end
    error('MATLAB:hadamard:OrdreImpossible', ...
          ['HADAMARD ne construit que les ordres 1, 2, 12 et 20 multiplies ' ...
           'par une puissance de deux ; %d n''en est pas.'], n);
end
