function [ordre, directe, memoire] = matlibre_sl_ordre(modele)
%MATLIBRE_SL_ORDRE L'ordre dans lequel les blocs se calculent.
%   [ORDRE,DIRECTE,MEMOIRE] = MATLIBRE_SL_ORDRE(MODELE) rend l'ordre de
%   calcul des blocs, et pour chacun s'il transmet son entrée à l'instant
%   même et s'il porte un état.
%
%   Un bloc à transmission directe se calcule après ce qui l'alimente.
%   Un bloc qui n'en a pas — intégrateur, retard, mémoire, et une
%   représentation d'état dont D est nul — rend une valeur qui ne dépend
%   que de son état : il peut donc être placé le premier, et c'est ce qui
%   casse les boucles.
%
%   C'est la même règle que celle de SIM. Elle est ici pour que le
%   programme engendré par MATLIBRE_SL_PROGRAMME calcule dans le même
%   ordre — sans quoi il rendrait d'autres nombres que la simulation.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = new_system('c');
%      m = add_block(m, 'gain', 'k', 'Gain', 2);
%      m = add_block(m, 'constant', 'u', 'Value', 1);
%      m = add_line(m, 'u', 'k');
%      matlibre_sl_ordre(m)             % [2 1] : la source avant le gain
%
%   Voir aussi SIM, MATLIBRE_SL_PROGRAMME.
    n = numel(modele.blocs);
    directe = true(1, n);
    memoire = false(1, n);
    for k = 1:n
        bloc = modele.blocs{k};
        switch bloc.type
            case {'constant', 'step', 'ramp', 'sine', 'inport', 'fromworkspace'}
                directe(k) = false;   % une source n'a pas d'entrée
            case {'integrator', 'delay', 'unitdelay', 'memory', 'zoh', ...
                  'zeroorderhold'}
                directe(k) = false;
                memoire(k) = true;
            case 'transportdelay'
                directe(k) = lireNombre(bloc, 'DelayTime', 1) == 0;
                memoire(k) = true;
            case {'statespace', 'discretestatespace'}
                directe(k) = any(any(lireNombre(bloc, 'D', 0) ~= 0));
                memoire(k) = true;
            case 'transferfcn'
                [~, ~, ~, D] = tf2ss(lireNombre(bloc, 'Numerator', 1), ...
                                     lireNombre(bloc, 'Denominator', 1));
                directe(k) = any(any(D ~= 0));
                memoire(k) = true;
            case 'discreteintegrator'
                methode = lireTexte(bloc, 'IntegratorMethod', 'ForwardEuler');
                directe(k) = ~strcmpi(methode, 'ForwardEuler');
                memoire(k) = true;
            case 'discretetransferfcn'
                num = lireNombre(bloc, 'Numerator', 1);
                directe(k) = ~isempty(num) && num(1) ~= 0;
                memoire(k) = true;
            case {'relay', 'derivative', 'ratelimiter', 'pidcontroller'}
                memoire(k) = true;   % de la mémoire, mais transmission directe
        end
    end

    visite = zeros(1, n);
    ordre = [];
    for k = 1:n
        [ordre, visite] = visiter(modele, k, directe, visite, ordre);
    end
end

function [ordre, visite] = visiter(modele, k, directe, visite, ordre)
    if visite(k) ~= 0
        return
    end
    visite(k) = 2;
    if directe(k)
        for l = 1:size(modele.liens, 1)
            if modele.liens(l, 2) == k
                [ordre, visite] = visiter(modele, modele.liens(l, 1), directe, ...
                                          visite, ordre);
            end
        end
    end
    visite(k) = 1;
    ordre(end + 1) = k;
end

function v = lireNombre(bloc, nom, defaut)
    v = defaut;
    if isfield(bloc.parametres, nom)
        v = bloc.parametres.(nom);
    end
    if ischar(v) || isstring(v)
        v = matlibre_sl_expression(char(v), bloc.nom, nom);
    end
end

function v = lireTexte(bloc, nom, defaut)
    v = defaut;
    if isfield(bloc.parametres, nom)
        v = char(bloc.parametres.(nom));
    end
end
