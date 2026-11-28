% la boucle de référence : trois PID d'un degré, un par partie
function m = boucle76(nom, b, c, domaine, deux)
    m = new_system(nom);
    m = add_block(m, 'step', 'r', 'Time', 0.5);
    m = add_block(m, 'transferfcn', 'procede', 'Numerator', 1, 'Denominator', [1 2 1]);
    m = add_block(m, 'outport', 'y');
    reglages = {'P', 2, 'I', 1.5, 'D', 0.3, 'N', 20, 'TimeDomain', domaine};
    if strcmp(domaine, 'Discrete-time')
        reglages = [reglages, {'SampleTime', 0.01}];
    end
    if deux
        m = add_block(m, 'pidcontroller2dof', 'pid', reglages{:}, 'b', b, 'c', c);
        m = add_line(add_line(m, 'r', 'pid/1'), 'procede', 'pid/2');
        m = add_line(m, 'pid', 'procede');
    else
        % P (b r - y) + I (r - y) + D (c r - y) : trois PID d'un degré
        m = add_block(m, 'gain', 'b', 'Gain', b);
        m = add_block(m, 'gain', 'c', 'Gain', c);
        m = add_block(m, 'sum', 'eP', 'Signs', '+-');
        m = add_block(m, 'sum', 'eI', 'Signs', '+-');
        m = add_block(m, 'sum', 'eD', 'Signs', '+-');
        m = add_block(m, 'pidcontroller', 'pP', reglages{:}, 'Controller', 'P');
        m = add_block(m, 'pidcontroller', 'pI', reglages{:}, 'Controller', 'I');
        m = add_block(m, 'pidcontroller', 'pD', reglages{:}, 'Controller', 'PD', 'P', 0);
        m = add_block(m, 'sum', 'u', 'Signs', '+++');
        m = add_line(add_line(m, 'r', 'b'), 'r', 'c');
        m = add_line(add_line(m, 'b', 'eP', 1), 'r', 'eI', 1);
        m = add_line(m, 'c', 'eD', 1);
        for e = {'eP', 'eI', 'eD'}
            m = add_line(m, 'procede', [e{1} '/2']);
        end
        m = add_line(add_line(add_line(m, 'eP', 'pP'), 'eI', 'pI'), 'eD', 'pD');
        m = add_line(add_line(add_line(m, 'pP', 'u', 1), 'pI', 'u', 2), 'pD', 'u', 3);
        m = add_line(m, 'u', 'procede');
    end
    m = add_line(m, 'procede', 'y');
end
