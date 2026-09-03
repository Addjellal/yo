function refuserHorsSpline(Nr, Nd, famille)
%REFUSERHORSSPLINE Écarte les biorthogonales qui ne sont pas des splines.
%   MATLAB nomme « bior5.5 » et « bior6.8 » deux couples de Cohen et
%   Daubechies ajustés au plus près de l'orthonormalité, non des splines :
%   ils ne sortent pas de la construction de FILTRESSPLINES, et rendre
%   autre chose sous leur nom tromperait l'appelant.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    horsSpline = [5 5; 6 8];
    for k = 1:size(horsSpline, 1)
        if Nr == horsSpline(k, 1) && Nd == horsSpline(k, 2)
            error('wavelet:biorwavf:HorsSpline', ...
                  ['%s%d.%d n''est pas une biorthogonale spline : c''est ' ...
                   'un couple ajusté au plus près de l''orthonormalité, ' ...
                   'que MatLibre ne construit pas.'], famille, ...
                  horsSpline(k, 1), horsSpline(k, 2));
        end
    end
end
