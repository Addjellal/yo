function H = matlibre_envoyer_epipole(e, centre)
%MATLIBRE_ENVOYER_EPIPOLE Homographie qui repousse un épipôle à l'infini.
%   H = MATLIBRE_ENVOYER_EPIPOLE(E,CENTRE) compose trois transformations :
%   la translation qui amène CENTRE à l'origine, la rotation qui pose
%   l'épipôle E sur l'axe des abscisses, et la matrice qui l'y envoie à
%   l'infini. Une fois E à l'infini, les droites épipolaires de l'image
%   sont parallèles à l'axe des x.
%
%   E est un vecteur homogène de trois composantes, CENTRE un point [x; y].
%
%   Exemple :
%      H = matlibre_envoyer_epipole([1; 0; 0.01], [50; 40]);
%      p = H * [1; 0; 0.01];
%      abs(p(3)) < 1e-12      % l'épipôle est bien à l'infini
%
%   Voir aussi ESTIMATEUNCALIBRATEDRECTIFICATION.
    e = e(:);
    T = [1 0 -centre(1); 0 1 -centre(2); 0 0 1];
    eCentre = T * e;
    rayon = hypot(eCentre(1), eCentre(2));
    if rayon < eps
        % L'épipôle est déjà au centre : aucune rotation ne le sort de là.
        H = eye(3);
        return
    end
    signe = 1;
    if eCentre(1) < 0
        signe = -1;
    end
    R = signe / rayon * [eCentre(1) eCentre(2) 0; -eCentre(2) eCentre(1) 0; 0 0 rayon];
    eTourne = R * eCentre;
    if abs(eTourne(1)) < eps
        G = eye(3);
    else
        G = [1 0 0; 0 1 0; -eTourne(3) / eTourne(1) 0 1];
    end
    retour = [1 0 centre(1); 0 1 centre(2); 0 0 1];
    H = retour * G * R * T;
end
