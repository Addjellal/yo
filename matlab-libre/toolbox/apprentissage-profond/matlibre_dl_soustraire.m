function p = matlibre_dl_soustraire(p, avance)
%MATLIBRE_DL_SOUSTRAIRE Retranche un pas à un paramètre, sans l'enregistrer.
%   P = MATLIBRE_DL_SOUSTRAIRE(P,AVANCE) rend le paramètre mis à jour. La
%   mise à jour d'un solveur ne doit pas s'inscrire sur la bande : elle a
%   lieu entre deux dérivations, pas à l'intérieur d'une.
%
%   Exemple :
%      p = matlibre_dl_soustraire(dlarray(1), 0.25);
%      extractdata(p)      % 0.75
%
%   Voir aussi ADAMUPDATE, SGDMUPDATE, RMSPROPUPDATE.
    if isa(p, 'dlarray')
        p = matlibre_dl_construire(p.Valeur - avance, p.Format, 0);
    else
        p = p - avance;
    end
end
