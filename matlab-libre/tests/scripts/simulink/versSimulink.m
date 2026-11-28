function m = versSimulink(m, source, cible, varargin)
    % Un signal physique rendu à Simulink : SOURCE entre dans CIBLE par un
    % PS-Simulink Converter, un seul par source.
    nom = ['PSS_' strrep(source, '/', '_')];
    if ~any(cellfun(@(b) strcmp(b.nom, nom), m.blocs))
        m = add_block(m, 'pssimulinkconverter', nom);
        m = add_line(m, source, nom);
    end
    m = add_line(m, nom, cible, varargin{:});
end
