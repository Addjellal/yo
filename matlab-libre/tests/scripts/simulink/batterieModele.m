% Un modèle : le bloc T, ses entrées nourries par des sources, ses
% sorties vers des OUTPORT ; la première entrée peut venir d'un autre bloc.
function [s, ok] = batterieModele(nom, types, valeur)
    s = new_system(nom);
    ok = false;
    for q = 1:numel(types)
        s = add_block(s, types{q}, sprintf('b%d', q));
    end
    for q = 1:numel(types)
        [ne, ns] = matlibre_sl_ports(s.blocs{q});
        if isnan(ne), ne = 1; end
        if isnan(ns), ns = 1; end
        if q < numel(types) && (ns == 0 || ne == 0 && q > 1)
            return
        end
        premiere = 1 + (q > 1);
        for i = premiere:ne
            source = sprintf('c%d_%d', q, i);
            s = add_block(s, 'constant', source, 'Value', valeur);
            s = add_line(s, [source '/1'], sprintf('b%d/%d', q, i));
        end
        for j = 1 + (q < numel(types)):ns
            puits = sprintf('o%d_%d', q, j);
            s = add_block(s, 'outport', puits);
            s = add_line(s, sprintf('b%d/%d', q, j), [puits '/1']);
        end
        if q < numel(types)
            [ne2, ~] = matlibre_sl_ports(s.blocs{q + 1});
            if ~isnan(ne2) && ne2 == 0
                return
            end
            s = add_line(s, sprintf('b%d/1', q), sprintf('b%d/1', q + 1));
        end
    end
    ok = true;
end
