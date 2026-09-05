function prises = matlibre_id_prises_registre(ordre)
%MATLIBRE_ID_PRISES_REGISTRE Positions bouclées d'un registre à décalage.
%   P = MATLIBRE_ID_PRISES_REGISTRE(ORDRE) rend les positions dont la
%   somme, modulo deux, alimente l'entrée du registre. Ces positions sont
%   celles d'un polynôme primitif : c'est ce qui garantit que la suite
%   parcourt tous les états avant de se répéter.
%
%   Exemple :
%      matlibre_id_prises_registre(9)      % 5 9
%
%   Voir aussi MATLIBRE_ID_PRBS.
    table = {[1 2], [2 3], [3 4], [3 5], [5 6], [6 7], [4 5 6 8], [5 9], [7 10], ...
             [9 11], [6 8 11 12], [9 10 12 13], [4 8 13 14], [14 15], ...
             [4 13 15 16], [14 17], [11 18], [14 17 18 19], [17 20]};
    if ordre < 2 || ordre > numel(table) + 1
        error('ident:prbs:Ordre', 'Ordre de registre non traité : %d.', ordre);
    end
    prises = table{ordre - 1};
end
