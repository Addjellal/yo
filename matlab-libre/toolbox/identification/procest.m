function modele = procest(donnees, type, varargin)
%PROCEST Estimation d'un modèle de procédé.
%   M = PROCEST(Z,TYPE) ajuste un modèle décrit par ses constantes de
%   temps : 'P1' un premier ordre, 'P2' un second, la lettre 'D' ajoutant
%   un retard, 'Z' un zéro, 'I' un intégrateur.
%
%   L'ajustement minimise l'erreur de simulation. Le point de départ vient
%   d'une estimation par fonction de transfert, dont on lit le gain
%   statique et les constantes de temps : partir de valeurs quelconques
%   ferait tomber la descente dans un minimum local, le retard étant
%   particulièrement mal conditionné.
%
%   Exemple :
%      rng(1);
%      t = (0:0.2:60)';
%      u = double(t > 5);
%      vrai = idproc('P1D', 'K', 2, 'Tp1', 4, 'Td', 1);
%      z = sim(vrai, iddata([], u, 0.2));
%      m = procest(iddata(z.y, u, 0.2), 'P1D');
%      [m.K, m.Tp1, m.Td]      % environ 2, 4, 1
%
%   Voir aussi IDPROC, TFEST, SSEST.
    donnees = iddata(donnees);
    jeu = matlibre_id_experience(donnees, 1);
    type = upper(char(type));
    [depart, bornesBasses, bornesHautes, poser] = matlibre_id_proc_depart(jeu, type);
    reglages = optimset('MaxIter', 300, 'TolFun', 1e-10, 'TolX', 1e-10, 'Display', 'off');
    p = lsqnonlin(@(p) matlibre_id_proc_residu(p, poser, jeu), depart, ...
                  bornesBasses, bornesHautes, reglages);
    modele = poser(p);
    residus = matlibre_id_proc_residu(p, poser, jeu);
    modele.NoiseVariance = sum(residus .^ 2) / max(numel(residus) - numel(p), 1);
    modele.Ts = jeu.Ts;
    erreur = mean(residus .^ 2);
    ajustement = compareFit(jeu.OutputData, jeu.OutputData - residus);
    modele.Report = struct('Method', 'procest', 'OrderInfo', type, ...
                           'Fit', struct('FitPercent', ajustement, 'MSE', erreur, ...
                                         'FPE', erreur, 'AIC', 0, ...
                                         'nobs', numel(residus), 'nparams', numel(p)));
end
