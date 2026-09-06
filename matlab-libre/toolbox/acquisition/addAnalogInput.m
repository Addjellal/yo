function session = addAnalogInput(session, nom, generateur)
%ADDANALOGINPUT Ajoute une voie d'entrée.
%   SESSION = ADDANALOGINPUT(SESSION,NOM,GENERATEUR) ajoute une voie.
%   GENERATEUR est une poignée @(t) qui donne la tension à l'instant t ;
%   par défaut, un sinus à cinquante hertz.
%
%   Les voies se lisent ensemble et aux mêmes instants : c'est la
%   simultanéité qui fait l'intérêt d'une carte multivoie, et elle permet
%   de mesurer un déphasage — donc une puissance active — que deux
%   acquisitions séparées ne donneraient pas.
%
%   Le générateur peut porter du bruit : @(t) 2.5 + 0.1 * randn() simule
%   une tension continue bruitée, sur laquelle on peut éprouver le gain
%   d'un moyennage.
%
%   Exemple :
%      s = addAnalogInput(s, 'tension', @(t) 5 * sin(2*pi*50*t));
%      s = addAnalogInput(s, 'courant', @(t) 0.4 * sin(2*pi*50*t - pi/6));
%
%   Voir aussi DAQ, READDATA, ADDANALOGOUTPUT.
    if nargin < 3
        generateur = @(t) sin(2 * pi * 50 * t);
    end
    voie = struct('nom', nom, 'generateur', generateur);
    session.entrees{end+1} = voie;
end
