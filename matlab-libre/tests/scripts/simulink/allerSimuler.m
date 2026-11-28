% Simuler, et rendre les sorties, ou l'identifiant de l'erreur.
function [y, id] = allerSimuler(s, regle)
    y = [];
    id = 'ok';
    try
        evalc('r = sim(s, regle{:});');
        y = double(r.yout);
    catch err
        id = err.identifier;
        if isempty(id)
            id = 'refus';
        end
    end
end
