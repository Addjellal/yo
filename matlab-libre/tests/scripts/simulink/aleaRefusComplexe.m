% Un modèle où un signal complexe arrive sur l'entrée 1 du bloc b ; ses
% autres entrées reçoivent des réels.
function m = aleaRefusComplexe(type, varargin)
    m = new_system('refus');
    m = add_block(m, 'constant', 'c', 'Value', 1 + 1i);
    m = add_block(m, 'constant', 'r', 'Value', 1);
    m = add_block(m, type, 'b', varargin{:});
    [ne, ns] = matlibre_sl_ports(m.blocs{end});
    m = add_line(m, 'c', 'b/1');
    for j = 2:ne
        m = add_line(m, 'r', sprintf('b/%d', j));
    end
    for q = 1:ns
        nom = sprintf('y%d', q);
        m = add_line(add_block(m, 'outport', nom), sprintf('b/%d', q), nom);
    end
end
