function resume = summary(modele)
%SUMMARY Résumé d'un contrôle a posteriori.
%   S = SUMMARY(V) compte les observations, les dépassements observés et
%   attendus, et le niveau effectivement atteint. Sans sortie, le résumé
%   est écrit.
%
%   Exemple :
%      summary(varbacktest(rendements, valeursEnRisque))
%
%   Voir aussi VARBACKTEST, ESBACKTEST, RUNTESTS.
    if ~isa(modele, 'varbacktest') && ~isa(modele, 'esbacktest')
        error('risque:summary:Modele', ...
              'SUMMARY attend un contrôle de valeur en risque ou de perte moyenne.');
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
