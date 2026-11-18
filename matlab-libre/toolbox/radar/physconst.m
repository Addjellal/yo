function valeur = physconst(nom)
%PHYSCONST Constantes physiques des toolboxes de radar et d'antennes.
%   C = PHYSCONST(NOM) rend la constante NOM, comme MATLAB :
%      'LightSpeed'   vitesse de la lumière dans le vide, 299 792 458 m/s
%      'Boltzmann'    constante de Boltzmann, 1,380649e-23 J/K (CODATA, SI 2019)
%      'EarthRadius'  rayon moyen de la Terre, 6 371 000 m
%
%   Exemple :
%      lambda = physconst('LightSpeed') / 1e9     % 0.2998 m à 1 GHz
%      10 * log10(physconst('Boltzmann') * 290)   % -203.98 dBW/Hz
%
%   Voir aussi RADAREQPOW, RADAREQRNG, RADAREQSNR, RANGE2TIME.
    if ~(ischar(nom) || (isstring(nom) && isscalar(nom)))
        error('phased:physconst:Nom', 'Le nom de la constante est un texte.');
    end
    switch lower(char(nom))
        case 'lightspeed'
            valeur = 299792458;
        case 'boltzmann'
            valeur = 1.380649e-23;
        case 'earthradius'
            valeur = 6371000;
        otherwise
            error('phased:physconst:Nom', ...
                  'Constante inconnue : %s (LightSpeed, Boltzmann, EarthRadius).', char(nom));
    end
end
