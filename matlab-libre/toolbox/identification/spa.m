function modele = spa(donnees, M, pulsations)
%SPA Analyse spectrale de la réponse fréquentielle.
%   G = SPA(Z) estime la réponse fréquentielle par le rapport du
%   spectre croisé entrée-sortie au spectre de l'entrée :
%
%      G(w) = Phi_yu(w) / Phi_u(w)
%
%   Les spectres sont obtenus en pondérant les covariances par une fenêtre
%   de Hann avant de les transformer. C'est la méthode de Blackman et
%   Tukey : tronquer les covariances aux petits décalages écarte le bruit,
%   qui s'y accumule faute de moyenne, au prix d'une résolution
%   fréquentielle limitée par la largeur de la fenêtre.
%
%   G = SPA(Z,M) impose cette largeur ; G = SPA(Z,M,W) les pulsations.
%
%   Exemple :
%      g = spa(z, 40);
%      bode(g);
%
%   Voir aussi ETFE, IDFRD, TFEST.
    donnees = iddata(donnees);
    jeu = matlibre_id_experience(donnees, 1);
    y = jeu.OutputData;
    u = jeu.InputData;
    n = numel(y);
    if nargin < 2 || isempty(M)
        M = min(30, floor(n / 5));
    end
    M = round(M);
    if nargin < 3 || isempty(pulsations)
        pulsations = linspace(0, pi / jeu.Ts, 128).';
    else
        pulsations = double(pulsations(:));
    end
    fenetre = matlibre_id_fenetre_hann(M);
    decalages = (-M:M).';
    if isempty(u)
        spectreEntree = [];
        croise = [];
    else
        croise = matlibre_id_covariance(y, u, M) .* fenetre;
        spectreEntree = matlibre_id_covariance(u, u, M) .* fenetre;
    end
    spectreSortie = matlibre_id_covariance(y, y, M) .* fenetre;
    exposant = exp(-1i * (pulsations * jeu.Ts) * decalages.');
    if isempty(u)
        reponse = [];
    else
        reponse = (exposant * croise) ./ (exposant * spectreEntree);
    end
    modele = idfrd(reponse, pulsations, jeu.Ts);
    modele.SpectrumData = real(exposant * spectreSortie) * jeu.Ts;
    modele.Report = struct('Method', 'spa');
end
