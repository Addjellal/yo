function exigerPremier(p, nomFonction)
%EXIGERPREMIER Refuse un ordre de corps qui n'est pas premier.
%   Les corps de Galois d'ordre non premier se construisent par extension
%   et ne se réduisent pas à l'arithmétique modulaire : accepter un p
%   composé donnerait des résultats faux sans le dire.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    p = double(p);
    if ~isscalar(p) || p < 2 || p ~= round(p) || ~isprime(p)
        error('comm:gf:Premier', ...
              '%s demande un ordre de corps premier ; %g ne l''est pas.', ...
              nomFonction, p);
    end
end
