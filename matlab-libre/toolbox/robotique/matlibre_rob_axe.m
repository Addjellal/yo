function R = matlibre_rob_axe(axe, angle)
%MATLIBRE_ROB_AXE Rotation élémentaire autour d'un axe numéroté.
%   R = MATLIBRE_ROB_AXE(AXE,ANGLE) rend la rotation d'ANGLE radians
%   autour de l'axe 1, 2 ou 3 — x, y ou z.
%
%   ROTX, ROTY et ROTZ font la même chose en degrés et par trois
%   fonctions distinctes ; ici l'axe est un nombre, ce qui permet de
%   composer une séquence quelconque dans une boucle.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    c = cos(angle);
    s = sin(angle);
    switch axe
        case 1
            R = [1 0 0; 0 c -s; 0 s c];
        case 2
            R = [c 0 s; 0 1 0; -s 0 c];
        otherwise
            R = [c -s 0; s c 0; 0 0 1];
    end
end
