function valeur = evm(recus, references)
%EVM Amplitude du vecteur d'erreur, en pour cent.
%   VALEUR = EVM(RECUS,REFERENCES) rend la racine du rapport entre la
%   puissance de l'erreur et celle de la référence, en pour cent.
%
%   C'est la mesure de qualité d'une modulation numérique : elle rapporte
%   l'erreur à la référence, donc elle ne dépend pas du niveau. Elle se
%   relie directement au rapport signal à bruit — l'EVM en pour cent vaut
%   cent fois l'inverse de la racine du RSB.
%
%   Vingt décibels de RSB donnent donc dix pour cent d'EVM, trente
%   décibels trois pour cent. Les normes de radiocommunication fixent des
%   plafonds d'EVM par ordre de modulation : plus la constellation est
%   dense, moins on tolère d'erreur.
%
%   Exemple :
%      evm(reference, reference)       % 0
%      evm(reference + 0.1 * bruit, reference)
%
%   Voir aussi OFDMMOD, OFDMDEMOD.
    e = recus(:) - references(:);
    valeur = 100 * sqrt(mean(abs(e) .^ 2) / mean(abs(references(:)) .^ 2));
end
