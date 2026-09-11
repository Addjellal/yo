function v = matlibre_texte_ou_nombre(texte)
%MATLIBRE_TEXTE_OU_NOMBRE Convertit un texte en nombre s'il en est un.
%   Un texte qui s'écrit entièrement comme un nombre est rendu en nombre ;
%   tout autre reste du texte. C'est ce qui permet à un aller-retour par
%   WRITESTRUCT et READSTRUCT de rendre les nombres tels qu'on les a
%   donnés, sans rien reconvertir à la main.
%
%   La conversion exige que tout le texte soit consommé : « 12abc » reste
%   du texte, là où une conversion laxiste rendrait douze.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_texte_ou_nombre('42')       % 42, en nombre
%      matlibre_texte_ou_nombre('42abc')    % "42abc", en texte
%
%   Voir aussi READSTRUCT, STR2DOUBLE, STR2NUM.
    texte = char(texte);
    if isempty(strtrim(texte))
        v = "";
        return
    end
    nombre = str2double(texte);
    if ~isnan(nombre) && ~isempty(regexp(strtrim(texte), ...
            '^[-+]?(\d+\.?\d*|\.\d+)([eE][-+]?\d+)?$', 'once'))
        v = nombre;
    else
        v = string(texte);
    end
end
