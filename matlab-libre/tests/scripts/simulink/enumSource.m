function r = enumSource(varargin)
    % Une constante réglée comme on le dit.
    m = new_system('source');
    m = add_block(m, 'constant', 'c', varargin{:});
    m = add_block(m, 'outport', 'y');
    m = add_line(m, 'c/1', 'y/1');
    r = sim(m, 'StopTime', 0.02);
end
