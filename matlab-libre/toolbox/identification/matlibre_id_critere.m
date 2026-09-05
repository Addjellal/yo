function valeur = matlibre_id_critere(modele, nom)
%MATLIBRE_ID_CRITERE Une mesure du compte rendu d'estimation.
%   V = MATLIBRE_ID_CRITERE(MODELE,NOM) lit le champ demandé dans le
%   rapport laissé par l'estimation.
%
%   Exemple :
%      matlibre_id_critere(arx(z, [1 1 1]), 'MSE')
%
%   Voir aussi FPE, AIC.
    if isempty(modele.Report) || ~isfield(modele.Report, 'Fit')
        error('ident:critere:Absent', ...
              'Ce modèle ne porte pas de compte rendu d''estimation.');
    end
    ajustement = modele.Report.Fit;
    if ~isfield(ajustement, nom)
        error('ident:critere:Champ', 'Mesure inconnue : %s.', nom);
    end
    valeur = ajustement.(nom);
end
