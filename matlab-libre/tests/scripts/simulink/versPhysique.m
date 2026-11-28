function m = versPhysique(m, source, cible, varargin)
    % Un signal de Simulink rendu physique, comme Simscape le veut : SOURCE
    % entre dans CIBLE par un Simulink-PS Converter, un seul par source.
    nom = ['SPS_' strrep(source, '/', '_')];
    if ~any(cellfun(@(b) strcmp(b.nom, nom), m.blocs))
        m = add_block(m, 'simulinkpsconverter', nom);
        m = add_line(m, source, nom);
    end
    m = add_line(m, nom, cible, varargin{:});
end
