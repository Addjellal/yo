function [p, tableau] = anova1(y, groupe)
%ANOVA1 Analyse de variance à un facteur.
%   P = ANOVA1(Y,GROUPE) teste l'égalité des moyennes des groupes.
    y = y(:);
    groupe = groupe(:);
    g = unique(groupe);
    k = numel(g);
    n = numel(y);
    moyenneGenerale = mean(y);
    sceInter = 0;
    sceIntra = 0;
    for i = 1:k
        yi = y(groupe == g(i));
        sceInter = sceInter + numel(yi) * (mean(yi) - moyenneGenerale) ^ 2;
        sceIntra = sceIntra + sum((yi - mean(yi)) .^ 2);
    end
    ddlInter = k - 1;
    ddlIntra = n - k;
    F = (sceInter / ddlInter) / (sceIntra / ddlIntra);
    p = 1 - fcdf(F, ddlInter, ddlIntra);
    tableau = struct('SSB', sceInter, 'SSW', sceIntra, 'dfB', ddlInter, ...
                     'dfW', ddlIntra, 'F', F);
end
