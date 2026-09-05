function modele = n4sid(donnees, ordre, varargin)
%N4SID Identification d'un modèle d'état par sous-espaces.
%   M = N4SID(Z,N) estime un modèle d'état d'ordre N sans itération ni
%   point de départ : la structure du modèle se lit dans la géométrie des
%   données.
%
%   Le principe : ranger les mesures en matrices de Hankel — le passé
%   d'un côté, l'avenir de l'autre —, projeter l'avenir sur le passé le
%   long des entrées futures, et décomposer le résultat en valeurs
%   singulières. Le rang de cette projection est l'ordre du système, et
%   ses vecteurs propres portent la matrice d'observabilité, d'où A et C
%   se lisent par décalage. B, D et l'état initial s'obtiennent ensuite
%   par moindres carrés, le problème étant linéaire en eux.
%
%   M = N4SID(Z,'best') essaie les ordres de un à dix et garde celui dont
%   le critère d'erreur finale de prédiction est le plus petit.
%
%   Options : 'Horizon' (le nombre de blocs de Hankel, par défaut deux
%   fois l'ordre plus deux).
%
%   Exemple :
%      rng(1);
%      u = sign(randn(400, 1));
%      y = filter([0 0.5 0.2], [1 -1.2 0.4], u);
%      m = n4sid(iddata(y, u), 2);
%      sort(abs(eig(m.A)))      % les modules des poles vrais
%
%   Voir aussi SSEST, IDSS, ARX, TFEST.
    donnees = iddata(donnees);
    if ischar(ordre) || isstring(ordre)
        modele = matlibre_id_meilleur_ordre(donnees, @(n) n4sid(donnees, n, varargin{:}));
        return
    end
    ordre = round(ordre);
    horizon = 2 * ordre + 2;
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'horizon')
            horizon = round(double(varargin{k + 1}));
        end
    end
    jeu = matlibre_id_experience(donnees, 1);
    y = jeu.OutputData;
    u = jeu.InputData;
    if isempty(u)
        u = zeros(size(y));
    end
    [A, C] = matlibre_id_sous_espaces(y, u, ordre, horizon);
    [B, D, x0] = matlibre_id_entree_sortie(A, C, y, u);
    modele = idss(A, B, C, D, [], x0, jeu.Ts);
    residus = y - matlibre_id_parcourir_etat(modele, u, x0);
    parametres = ordre * ordre + ordre * size(u, 2) + size(y, 2) * ordre + ...
                 size(y, 2) * size(u, 2);
    modele.NoiseVariance = sum(residus(:) .^ 2) / max(numel(residus) - parametres, 1);
    modele = matlibre_id_rapport_etat(modele, jeu, 'n4sid', numel(residus), parametres);
end
