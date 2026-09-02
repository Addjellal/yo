function v = matlibre_tirer_atome(atome)
%MATLIBRE_TIRER_ATOME Une valeur au hasard d'un paramètre incertain.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   USAMPLE, WCGAIN et ROBSTAB s'en servent ; chaque genre de paramètre a
%   sa loi de tirage.
    switch atome.Kind
        case 'complex'
            % Uniforme dans le disque : la racine du rayon, pour que la
            % densite soit uniforme en surface et non en rayon.
            rayon = atome.Range(2) * sqrt(rand());
            angle = 2 * pi * rand();
            v = atome.Nominal + rayon * exp(1i * angle);
        case 'ltidyn'
            % Un premier ordre de gain au plus egal a la borne, dont le
            % pole est tire sur quelques decades.
            gain = atome.Range(2) * (2 * rand() - 1);
            pulsation = 10 ^ (2 * rand() - 1);
            v = ss(tf(gain * pulsation, [1 pulsation]));
        otherwise
            bas = atome.Range(1);
            haut = atome.Range(2);
            v = bas + (haut - bas) * rand();
    end
end
