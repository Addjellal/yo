function modele = tfest(donnees, poles, zeros_, retard, varargin)
%TFEST Estimation d'une fonction de transfert.
%   M = TFEST(Z,NP) estime une fonction de transfert à NP pôles.
%   M = TFEST(Z,NP,NZ) fixe aussi le nombre de zéros.
%   M = TFEST(Z,NP,NZ,RETARD) impose le retard, en échantillons.
%
%   L'estimation passe par un modèle sortie-erreur : c'est le même
%   problème, écrit autrement, et il a l'avantage de ne pas biaiser le
%   résultat quel que soit le bruit sur la sortie.
%
%   TFEST(...,'Ts',0) rend un modèle à temps continu, obtenu du modèle
%   discret par correspondance exacte du blocage d'ordre zéro.
%
%   Exemple :
%      rng(1);
%      u = sign(randn(600, 1));
%      y = filter([0 0.5], [1 -0.8], u) + 0.05 * randn(600, 1);
%      m = tfest(iddata(y, u, 1), 1, 0);
%      [num, den] = tfdata(m, 'v');
%
%   Voir aussi OE, IDTF, SSEST, PROCEST.
    donnees = iddata(donnees);
    poles = round(poles);
    if nargin < 3 || isempty(zeros_)
        zeros_ = max(poles - 1, 0);
    end
    zeros_ = round(zeros_);
    if nargin < 4 || isempty(retard)
        retard = 0;
    end
    continu = false;
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'ts') && double(varargin{k + 1}) == 0
            continu = true;
        end
    end
    nk = round(retard);
    sortieErreur = oe(donnees, [zeros_ + 1, poles, nk]);
    % Le retard est sorti du numérateur et porté à part : c'est la
    % convention de MATLAB, et c'est ce qui permet de convertir la partie
    % rationnelle vers le temps continu sans que le retard s'y perde.
    numerateur = sortieErreur.B((nk + 1):end);
    modele = idtf(numerateur, sortieErreur.F, donnees.Ts);
    modele.IODelay = nk * donnees.Ts;
    if continu
        % Le numérateur est complété à droite, non à gauche : complété à
        % gauche, il vaudrait un retard d'un échantillon de plus, et le
        % retard serait compté deux fois.
        plein = [numerateur, zeros(1, numel(sortieErreur.F) - numel(numerateur))];
        systeme = d2c(tf(plein, sortieErreur.F, donnees.Ts), 'zoh');
        [numerateurContinu, denominateurContinu] = tfdata(systeme, 'v');
        modele = idtf(numerateurContinu, denominateurContinu, 0);
        modele.IODelay = nk * donnees.Ts;
    end
    modele.NoiseVariance = sortieErreur.NoiseVariance;
    modele.Report = sortieErreur.Report;
    modele.Report.Method = 'tfest';
end
