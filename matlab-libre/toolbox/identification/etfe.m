function modele = etfe(donnees, M, N)
%ETFE Estimation empirique de la réponse fréquentielle.
%   G = ETFE(Z) rend le rapport des transformées de Fourier de la sortie
%   et de l'entrée, fréquence par fréquence. C'est l'estimateur le plus
%   direct qui soit : aucune structure n'est supposée, aucun paramètre
%   n'est ajusté.
%
%   Sa variance ne décroît pas quand les données s'accumulent — chaque
%   fréquence n'est estimée que par un point de la transformée. C'est
%   pourquoi G = ETFE(Z,M) lisse le résultat par une fenêtre de largeur M
%   sur les décalages : on échange alors de la résolution fréquentielle
%   contre de la précision, et c'est le seul moyen d'en gagner.
%
%   G = ETFE(Z,M,N) impose le nombre de points de fréquence.
%
%   Exemple :
%      g = etfe(z, 30);
%      bode(g);
%
%   Voir aussi SPA, IDFRD, TFEST.
    donnees = iddata(donnees);
    jeu = matlibre_id_experience(donnees, 1);
    y = jeu.OutputData;
    u = jeu.InputData;
    if isempty(u)
        error('ident:etfe:Entree', 'ETFE demande une entrée.');
    end
    if nargin >= 2 && ~isempty(M) && isfinite(M)
        modele = spa(jeu, M);
        modele.Report = struct('Method', 'etfe');
        return
    end
    n = numel(y);
    if nargin < 3 || isempty(N)
        N = n;
    end
    Y = fft(y, N);
    U = fft(u, N);
    moitie = floor(N / 2) + 1;
    reponse = Y(1:moitie) ./ U(1:moitie);
    pulsations = (0:(moitie - 1)).' * 2 * pi / (N * jeu.Ts);
    modele = idfrd(reponse, pulsations, jeu.Ts);
    modele.SpectrumData = abs(Y(1:moitie)) .^ 2 / n;
    modele.Report = struct('Method', 'etfe');
end
