function v = fnval(f, x)
%FNVAL Évalue une fonction par morceaux.
%   V = FNVAL(F,X) évalue la spline F aux abscisses X, que F soit donnée
%   sous forme de morceaux polynomiaux — celle que rendent SPLINE et
%   CSAPS — ou sous forme de B-splines, celle que rend SPAP2.
%
%   FNVAL(X,F) est accepté aussi : l'ordre des arguments n'importe pas,
%   comme dans MATLAB.
%
%   Exemple :
%      fnval(spline(1:5, (1:5).^2), 2.5)      % 6.25
%
%   Voir aussi PPVAL, FNDER, FNINT, FNBRK, FNPLT.
    if isnumeric(f) && isstruct(x)
        [f, x] = deal(x, f);
    end
    if ~isstruct(f) || ~isfield(f, 'form')
        error('curvefit:fnval:Forme', ...
              'FNVAL attend une spline sous forme « pp » ou « B- ».');
    end
    if strncmp(f.form, 'B', 1)
        v = matlibre_bspline_valeurs(f.knots, f.order, f.coefs, x);
    else
        v = ppval(f, x);
    end
end
