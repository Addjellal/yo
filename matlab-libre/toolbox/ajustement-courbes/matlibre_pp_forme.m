function pp = matlibre_pp_forme(f)
%MATLIBRE_PP_FORME Spline ramenée à la forme par morceaux.
%   PP = MATLIBRE_PP_FORME(F) rend F telle quelle si elle est déjà en
%   morceaux polynomiaux, et la convertit si elle est en B-splines.
%
%   Exemple :
%      pp = matlibre_pp_forme(spline(1:4, [1 2 3 4]));
%
%   Voir aussi FNDER, FNINT, SPAP2.
    if ~isstruct(f) || ~isfield(f, 'form')
        error('curvefit:forme:Inconnue', 'Spline attendue.');
    end
    if strncmp(f.form, 'B', 1)
        pp = matlibre_bspline_vers_pp(f);
    else
        pp = f;
        if ~isfield(pp, 'dim')
            pp.dim = 1;
        end
    end
end
