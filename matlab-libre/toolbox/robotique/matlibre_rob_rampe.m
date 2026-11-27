function ta = matlibre_rob_rampe(distance, T, vitesse, acceleration, tempsRampe, d)
%MATLIBRE_ROB_RAMPE Durée de la rampe d'un profil trapézoïdal.
%   Sur un segment de durée T et de distance D, un profil trapézoïdal de
%   temps de rampe ta a pour aire v(T - ta), avec v la vitesse de palier.
%   Imposer l'une des trois grandeurs fixe donc les deux autres :
%
%      v = D / (T - ta)        ta = T - D / v
%      a = v / ta              ta = (T - sqrt(T^2 - 4 D / a)) / 2
%
%   Sans consigne, la rampe occupe le tiers de la durée.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if abs(distance) < eps
        ta = T / 3;
        return
    end
    if ~isempty(tempsRampe)
        ta = matlibre_rob_choisir(tempsRampe, d);
    elseif ~isempty(vitesse)
        v = abs(matlibre_rob_choisir(vitesse, d));
        ta = T - abs(distance) / v;
    elseif ~isempty(acceleration)
        a = abs(matlibre_rob_choisir(acceleration, d));
        sous = T ^ 2 - 4 * abs(distance) / a;
        if sous < 0
            error('robotics:trapveltraj:Acceleration', ...
                  ['The requested acceleration is not enough to cover the ' ...
                   'distance in the given time.']);
        end
        ta = (T - sqrt(sous)) / 2;
    else
        ta = T / 3;
    end
    if ta <= 0
        % L'aire d'un trapèze de hauteur v sur une durée T ne dépasse pas
        % v T : sous cette vitesse, la distance est hors d'atteinte.
        error('robotics:trapveltraj:Vitesse', ...
              ['The peak velocity is not enough: covering %g in %g ' ...
               'requires more than %g.'], abs(distance), T, abs(distance) / T);
    end
    if ta > T / 2
        error('robotics:trapveltraj:Rampe', ...
              ['The acceleration time is %g for a duration of %g: it cannot ' ...
               'exceed half of it, or the constant-velocity segment disappears.'], ta, T);
    end
end
