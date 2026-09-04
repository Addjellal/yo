function varargout = fnbrk(f, partie)
%FNBRK Extrait une partie d'une spline.
%   V = FNBRK(F,PARTIE) où PARTIE vaut 'breaks' — ou 'knots' pour une
%   B-spline —, 'coefs', 'pieces', 'order', 'dim' ou 'interval'.
%   FNBRK(F,I) où I est un entier rend le morceau numéro I, comme spline
%   à part entière.
%   [B,C,L,K] = FNBRK(F) rend d'un coup les nœuds, les coefficients, le
%   nombre de morceaux et l'ordre.
%
%   Exemple :
%      fnbrk(spline(1:5, (1:5).^2), 'order')      % 4
%
%   Voir aussi FNVAL, FNDER, FNINT, SPLINE.
    if nargin < 2
        pp = matlibre_pp_forme(f);
        varargout = {pp.breaks, pp.coefs, pp.pieces, pp.order};
        varargout = varargout(1:max(nargout, 1));
        return
    end
    if isnumeric(partie)
        pp = matlibre_pp_forme(f);
        indice = round(partie);
        if indice < 1 || indice > pp.pieces
            error('curvefit:fnbrk:Morceau', 'Il n''y a que %d morceaux.', pp.pieces);
        end
        varargout{1} = struct('form', 'pp', ...
                              'breaks', pp.breaks(indice:(indice + 1)), ...
                              'coefs', pp.coefs(indice, :), 'pieces', 1, ...
                              'order', pp.order, 'dim', 1);
        return
    end
    nom = lower(char(partie));
    if strncmp(f.form, 'B', 1) && any(strcmp(nom, {'knots', 'coefs', 'order', 'number'}))
        switch nom
            case 'knots',  varargout{1} = f.knots;
            case 'coefs',  varargout{1} = f.coefs;
            case 'order',  varargout{1} = f.order;
            case 'number', varargout{1} = f.number;
        end
        return
    end
    pp = matlibre_pp_forme(f);
    switch nom
        case {'breaks', 'knots'}, varargout{1} = pp.breaks;
        case 'coefs',             varargout{1} = pp.coefs;
        case 'pieces',            varargout{1} = pp.pieces;
        case 'order',             varargout{1} = pp.order;
        case 'dim',               varargout{1} = 1;
        case 'interval',          varargout{1} = [pp.breaks(1), pp.breaks(end)];
        case 'form',              varargout{1} = pp.form;
        otherwise
            error('curvefit:fnbrk:Partie', 'Partie inconnue : %s.', nom);
    end
end
