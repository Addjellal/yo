function position = matlibre_comm_position(symbole, M, ordre)
%MATLIBRE_COMM_POSITION Place d'un symbole dans la constellation.
%   P = MATLIBRE_COMM_POSITION(S,M,ORDRE) rend la position occupée par le
%   symbole S. En ordre binaire c'est S lui-même ; en ordre de Gray c'est
%   la place P telle que le code de Gray de P vaille S.
%
%   Le code de Gray d'un entier p est p XOR (p décalé d'un bit à droite).
%   La suite des codes de Gray parcourt tous les entiers en ne changeant
%   qu'un bit à chaque pas : c'est la seule propriété qui compte ici.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi PSKMOD, QAMMOD, MATLIBRE_COMM_SYMBOLE.
    symbole = double(symbole);
    if strcmpi(ordre, 'bin')
        position = symbole;
        return
    end
    if ~strcmpi(ordre, 'gray')
        error('comm:ordre:Inconnu', 'L''ordre vaut ''bin'' ou ''gray''.');
    end
    table = matlibre_comm_table_gray(M);
    inverse = zeros(1, M);
    inverse(table + 1) = 0:(M - 1);
    position = reshape(inverse(mod(symbole(:), M) + 1), size(symbole));
end
