function m = matlibre_atome(nom, nominal, plage, genre)
%MATLIBRE_ATOME Un paramètre incertain d'un genre quelconque, en UMAT.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   UCOMPLEX, ULTIDYN et UDYN s'en servent : leurs paramètres ne sont pas
%   des réels, mais ils vivent dans le même UMAT, avec un champ « Kind »
%   qui dit comment les tirer et comment les borner.
    parametres = {struct('Name', nom, 'Nominal', nominal, ...
                         'Range', plage, 'Kind', genre)};
    m = umat([], parametres, @(v) v.(nom), size(nominal));
end
