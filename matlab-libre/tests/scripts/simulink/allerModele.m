% Un bloc seul, réglé, ses entrées sur des constantes, ses sorties sur
% des Outport.
function [s, ok] = allerModele(type, reglage, valeur)
    s = add_block(new_system('aller94'), type, 'b1', reglage{:});
    ok = false;
    [ne, ns] = matlibre_sl_ports(s.blocs{1});
    if isnan(ne) || isnan(ns)
        return
    end
    for i = 1:ne
        source = sprintf('c%d', i);
        s = add_block(s, 'constant', source, 'Value', valeur);
        s = add_line(s, [source '/1'], sprintf('b1/%d', i));
    end
    for j = 1:ns
        puits = sprintf('o%d', j);
        s = add_block(s, 'outport', puits);
        s = add_line(s, sprintf('b1/%d', j), [puits '/1']);
    end
    ok = true;
end
