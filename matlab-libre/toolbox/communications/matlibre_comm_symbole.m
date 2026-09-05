function symbole = matlibre_comm_symbole(position, M, ordre)
%MATLIBRE_COMM_SYMBOLE Symbole porté par une position de la constellation.
%   S = MATLIBRE_COMM_SYMBOLE(P,M,ORDRE) est l'inverse de
%   MATLIBRE_COMM_POSITION : en ordre de Gray, la position P porte le
%   symbole dont le code de Gray vaut P.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi PSKDEMOD, QAMDEMOD, MATLIBRE_COMM_POSITION.
    position = double(position);
    if strcmpi(ordre, 'bin')
        symbole = position;
        return
    end
    if ~strcmpi(ordre, 'gray')
        error('comm:ordre:Inconnu', 'L''ordre vaut ''bin'' ou ''gray''.');
    end
    table = matlibre_comm_table_gray(M);
    symbole = reshape(table(mod(position(:), M) + 1), size(position));
end
