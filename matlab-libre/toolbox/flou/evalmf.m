function y = evalmf(x, type, parametres)
%EVALMF Évalue une fonction d'appartenance par son nom.
    switch lower(char(type))
        case 'trimf'
            y = trimf(x, parametres);
        case 'trapmf'
            y = trapmf(x, parametres);
        case 'gaussmf'
            y = gaussmf(x, parametres);
        case 'sigmf'
            y = sigmf(x, parametres);
        case 'gbellmf'
            y = gbellmf(x, parametres);
        otherwise
            error('fuzzy:evalmf:unknown', 'Unknown membership function ''%s''.', type);
    end
end
