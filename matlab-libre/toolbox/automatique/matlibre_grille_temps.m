function t = matlibre_grille_temps(sys, temps)
%MATLIBRE_GRILLE_TEMPS Grille de temps d'une simulation.
%   T = MATLIBRE_GRILLE_TEMPS(SYS,TEMPS) rend la grille sur laquelle
%   simuler le modèle SYS. TEMPS vide la fait choisir d'après les pôles :
%   huit fois la constante de temps la plus lente, bornée entre une
%   seconde et mille, en quatre cents points. Un scalaire donne l'horizon,
%   un vecteur donne la grille elle-même, qui doit être à pas fixe — la
%   réponse se calcule pas à pas, comme dans MATLAB, qui refuse de même
%   des instants inégalement espacés.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB.
%
%   Voir aussi STEP, IMPULSE, LSIM.
    if ~isempty(temps) && numel(temps) > 1
        t = temps(:);
        % la réponse se calcule à pas fixe : la grille doit l'être
        dt = t(2) - t(1);
        if ~all(isfinite(t)) || ~(dt > 0) || any(abs(diff(t) - dt) > 1e-6 * dt)
            error('Control:analysis:NonUniformTimeVector', ...
                  ['The time vector must be real, finite, and must contain monotonically ' ...
                   'increasing and evenly spaced time samples.']);
        end
        return;
    end
    if isempty(temps)
        p = pole(sys);
        vitesses = abs(real(p));
        vitesses = vitesses(vitesses > 1e-9);
        if isempty(vitesses)
            horizon = 10;
        else
            horizon = 8 / min(vitesses);
        end
        horizon = min(max(horizon, 1), 1000);
    else
        horizon = temps;
    end
    t = linspace(0, horizon, 400).';
end
