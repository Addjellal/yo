function modele = ssest(donnees, ordre, varargin)
%SSEST Estimation d'un modèle d'état par erreur de prédiction.
%   M = SSEST(Z,N) estime un modèle d'état d'ordre N. Le point de départ
%   vient de N4SID — qui, lui, n'a besoin d'aucun départ —, puis les
%   matrices sont affinées en minimisant l'erreur de simulation.
%
%   Cette seconde étape vaut la peine quand le bruit n'est pas blanc en
%   sortie : les méthodes par sous-espaces sont alors légèrement biaisées,
%   là où la minimisation de l'erreur ne l'est pas.
%
%   M = SSEST(Z,'best') choisit l'ordre par le critère d'erreur finale de
%   prédiction.
%
%   Options : 'MaxIter' (100).
%
%   Exemple :
%      m = ssest(z, 2);
%      compare(m, z);
%
%   Voir aussi N4SID, IDSS, POLYEST, TFEST.
    donnees = iddata(donnees);
    if ischar(ordre) || isstring(ordre)
        modele = matlibre_id_meilleur_ordre(donnees, @(n) ssest(donnees, n, varargin{:}));
        return
    end
    iterations = 100;
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'maxiter')
            iterations = round(double(varargin{k + 1}));
        end
    end
    depart = n4sid(donnees, ordre, varargin{:});
    jeu = matlibre_id_experience(donnees, 1);
    y = jeu.OutputData;
    u = jeu.InputData;
    if isempty(u)
        u = zeros(size(y));
    end
    p0 = matlibre_id_aplatir_etat(depart);
    reglages = optimset('MaxIter', iterations, 'TolFun', 1e-10, 'TolX', 1e-10, ...
                        'Display', 'off');
    p = lsqnonlin(@(p) matlibre_id_residu_etat(p, depart, y, u), p0, [], [], reglages);
    modele = matlibre_id_replier_etat(p, depart);
    residus = y - matlibre_id_parcourir_etat(modele, u, modele.x0);
    modele.NoiseVariance = sum(residus(:) .^ 2) / max(numel(residus) - numel(p), 1);
    modele = matlibre_id_rapport_etat(modele, jeu, 'ssest', numel(residus), numel(p));
end
