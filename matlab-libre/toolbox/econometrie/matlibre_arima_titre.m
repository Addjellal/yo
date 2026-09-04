function texte = matlibre_arima_titre(modele)
%MATLIBRE_ARIMA_TITRE Une ligne qui nomme le modèle ajusté.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isa(modele, 'garch')
        texte = sprintf('GARCH(%d,%d) — %s', modele.P, modele.Q, ...
                        matlibre_texte_loi(modele.Distribution));
        return
    end
    p = 0; q = 0;
    if ~isempty(modele.ARLags), p = max(modele.ARLags); end
    if ~isempty(modele.MALags), q = max(modele.MALags); end
    texte = sprintf('ARIMA(%d,%d,%d) — %s', p, modele.D, q, ...
                    matlibre_texte_loi(modele.Distribution));
end
