% Le bloc T, un paramètre mis à une valeur fautive, ses entrées nourries
% par des sinus, ses sorties vers des OUTPORT.
function s = batterieFautif(type, nom, valeur)
    s = new_system('fautif');
    s = add_block(s, type, 'b', nom, valeur);
    [ne, ns] = matlibre_sl_ports(s.blocs{end});
    if isnan(ne), ne = 1; end
    if isnan(ns), ns = 1; end
    for i = 1:ne
        s = add_block(s, 'sine', sprintf('c%d', i), 'Bias', 1.5);
        s = add_line(s, sprintf('c%d/1', i), sprintf('b/%d', i));
    end
    for j = 1:ns
        s = add_block(s, 'outport', sprintf('o%d', j));
        s = add_line(s, sprintf('b/%d', j), sprintf('o%d/1', j));
    end
end
