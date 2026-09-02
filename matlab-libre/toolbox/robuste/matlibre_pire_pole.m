function p = matlibre_pire_pole(modele)
%MATLIBRE_PIRE_POLE La plus grande partie réelle des pôles, ou son équivalent discret.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   ROBSTAB s'en sert : la stabilité se lit sur ce seul nombre, négatif
%   pour un modèle stable, quelle que soit sa taille. En discret, on rend
%   le logarithme du plus grand module, qui a le même signe.
    modele = ss(modele);
    if isempty(modele.A)
        p = -Inf;
        return
    end
    poles = eig(modele.A);
    if modele.Ts ~= 0
        p = log(max(abs(poles)));
        return
    end
    p = max(real(poles));
end
