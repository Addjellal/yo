function choisis = matlibre_sym_proches(noms, nombre)
%MATLIBRE_SYM_PROCHES Les variables les plus proches de « x ».
%   La règle est celle de MATLAB : on classe par distance à la lettre x
%   dans l'alphabet, les lettres qui la suivent passant avant celles qui
%   la précèdent à distance égale. C'est ce qui fait que DIFF(a*x^2)
%   dérive par rapport à x, non à a.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isempty(noms)
        choisis = {};
        return
    end
    distances = zeros(1, numel(noms));
    for k = 1:numel(noms)
        premiere = lower(noms{k}(1));
        ecart = double(premiere) - double('x');
        % À distance égale, la lettre qui suit x l'emporte.
        distances(k) = abs(ecart) * 2 + (ecart < 0);
    end
    [~, ordre] = sort(distances);
    nombre = min(nombre, numel(noms));
    choisis = noms(ordre(1:nombre));
    choisis = sort(choisis);
end
