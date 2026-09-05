function [q, qd, qdd, t, pp] = trapveltraj(points, nombre, varargin)
%TRAPVELTRAJ Trajectoire à profil de vitesse trapézoïdal.
%   [Q,QD,QDD,T] = TRAPVELTRAJ(POINTS,N) relie les points de passage par
%   des segments à vitesse trapézoïdale, et rend N échantillons.
%
%   Options :
%      'EndTime'       durée de chaque segment, un par défaut
%      'PeakVelocity'  vitesse du palier
%      'Acceleration'  accélération des rampes
%      'AccelTime'     durée de chaque rampe
%
%   Le profil monte en rampe, tient un palier, puis redescend. C'est le
%   profil des commandes d'axe les plus répandues : il atteint la
%   distance voulue dans le temps voulu sans jamais dépasser une vitesse
%   ni une accélération données — ce qu'aucun polynôme ne garantit.
%
%   Une seule des trois grandeurs vitesse, accélération et temps de rampe
%   suffit à fixer le profil : les deux autres s'en déduisent, la
%   distance et la durée étant imposées. Par défaut la rampe occupe un
%   tiers du temps de chaque côté.
%
%   Exemple :
%      [q, qd] = trapveltraj([0 2], 100);
%      max(qd)                         % la vitesse de palier
%      trapz(linspace(0, 1, 100), qd)  % 2 : l'aire vaut la distance
%
%   Voir aussi CUBICPOLYTRAJ, QUINTICPOLYTRAJ, BSPLINEPOLYTRAJ.
    points = double(points);
    nombre = round(double(nombre));
    nDegres = size(points, 1);
    nPoints = size(points, 2);
    duree = 1;
    vitesseCrete = [];
    acceleration = [];
    tempsRampe = [];
    for k = 1:2:numel(varargin)
        switch lower(char(varargin{k}))
            case 'endtime',      duree = double(varargin{k + 1});
            case 'peakvelocity', vitesseCrete = double(varargin{k + 1});
            case 'acceleration', acceleration = double(varargin{k + 1});
            case 'acceltime',    tempsRampe = double(varargin{k + 1});
            otherwise
                error('robotics:trapveltraj:Option', 'Option inconnue : %s.', ...
                      char(varargin{k}));
        end
    end
    if isscalar(duree)
        duree = repmat(duree, 1, nPoints - 1);
    end
    instants = [0, cumsum(duree)];
    t = linspace(0, instants(end), nombre);
    q = zeros(nDegres, nombre);
    qd = zeros(nDegres, nombre);
    qdd = zeros(nDegres, nombre);
    for s = 1:(nPoints - 1)
        T = duree(s);
        dedans = t >= instants(s) & t <= instants(s + 1);
        local = t(dedans) - instants(s);
        for d = 1:nDegres
            distance = points(d, s + 1) - points(d, s);
            ta = matlibre_rob_rampe(distance, T, vitesseCrete, acceleration, ...
                                    tempsRampe, d);
            [position, vitesse, acc] = matlibre_rob_trapeze(local, distance, T, ta);
            q(d, dedans) = points(d, s) + position;
            qd(d, dedans) = vitesse;
            qdd(d, dedans) = acc;
        end
    end
    pp = struct('form', 'trapeze', 'breaks', instants, 'pieces', nPoints - 1, ...
                'dim', nDegres);
end
