function session = addAnalogInput(session, nom, generateur)
%ADDANALOGINPUT Ajoute une voie d'entrée.
%   GENERATEUR est une poignée @(t) qui produit le signal mesuré.
    if nargin < 3
        generateur = @(t) sin(2 * pi * 50 * t);
    end
    voie = struct('nom', nom, 'generateur', generateur);
    session.entrees{end+1} = voie;
end
