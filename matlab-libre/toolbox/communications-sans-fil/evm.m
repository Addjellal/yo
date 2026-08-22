function valeur = evm(recus, references)
%EVM Amplitude du vecteur d'erreur, en pour cent.
    e = recus(:) - references(:);
    valeur = 100 * sqrt(mean(abs(e) .^ 2) / mean(abs(references(:)) .^ 2));
end
