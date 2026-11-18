function resume = summary(modele)
%SUMMARY Résumé d'un contrôle a posteriori.
%   S = SUMMARY(V), V un VARBACKTEST, rend la table de MATLAB : PortfolioID,
%   VaRID, VaRLevel, ObservedLevel (part des périodes sans dépassement),
%   Observations, Failures, Expected, Ratio (dépassements sur attendus),
%   FirstFailure (période du premier dépassement) et Missing (périodes
%   retirées pour valeur manquante). Pour un ESBACKTEST, une structure aux
%   mêmes comptes. Sans sortie, le résumé est écrit.
%
%   Exemple :
%      rng(1);
%      rendements = 0.01 * randn(500, 1);
%      valeursEnRisque = 0.023 * ones(500, 1);
%      summary(varbacktest(rendements, valeursEnRisque))
%
%   Voir aussi VARBACKTEST, ESBACKTEST, RUNTESTS.
    if ~isa(modele, 'varbacktest') && ~isa(modele, 'esbacktest')
        error('risque:summary:Modele', ...
              'SUMMARY attend un contrôle de valeur en risque ou de perte moyenne.');
    end
    if isa(modele, 'varbacktest')
        % La table de MATLAB : niveau observé, comptes, rapport à l'attendu,
        % premier dépassement, valeurs manquantes retirées.
        [echecs, N, x, attendu, manquants] = matlibre_var_echecs(modele);
        premier = find(echecs, 1);
        if isempty(premier)
            premier = NaN;
        end
        resume = table(string(modele.PortfolioID), string(modele.VaRID), modele.VaRLevel, ...
            1 - x / N, N, x, attendu, x / attendu, premier, manquants, 'VariableNames', ...
            {'PortfolioID', 'VaRID', 'VaRLevel', 'ObservedLevel', 'Observations', ...
             'Failures', 'Expected', 'Ratio', 'FirstFailure', 'Missing'});
        if nargout == 0
            disp(resume);
            clear resume
        end
        return
    end
    depassements = modele.PortfolioData < -modele.VaRData;
    N = numel(depassements);
    x = sum(depassements);
    resume = struct('PortfolioID', modele.PortfolioID, 'VaRID', modele.VaRID, ...
                    'VaRLevel', modele.VaRLevel, 'ObservedLevel', 1 - x / N, ...
                    'N', N, 'Failures', x, 'Expected', (1 - modele.VaRLevel) * N, ...
                    'Ratio', matlibre_part(x, (1 - modele.VaRLevel) * N), ...
                    'Missing', sum(isnan(modele.PortfolioData)));
    if nargout == 0
        fprintf('\n  %s / %s au niveau %.4f\n', resume.PortfolioID, resume.VaRID, ...
                resume.VaRLevel);
        fprintf('    %d observations, %d dépassements (attendus %.1f)\n', ...
                resume.N, resume.Failures, resume.Expected);
        fprintf('    niveau observé : %.4f\n\n', resume.ObservedLevel);
        clear resume
    end
end
