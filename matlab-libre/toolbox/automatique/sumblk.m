function S = sumblk(expression, largeur)
%SUMBLK Point de sommation, décrit par une équation.
%   S = SUMBLK('e = r - y') rend un modèle statique dont la sortie
%   s'appelle « e » et les entrées « r » et « y », avec les signes de
%   l'équation. C'est le bloc qu'on met dans un CONNECT pour faire une
%   différence ou une somme, sans écrire de matrice.
%
%   S = SUMBLK('e = r - y',N) répète le point de sommation sur N voies :
%   les signaux s'appellent alors e(1), e(2), et ainsi de suite.
%
%   Les termes peuvent porter un gain : 'e = r - 2*y'.
%
%   Exemple :
%      S = sumblk('e = r - y');
%      S.InputName'        % {'r', 'y'}
%      S.D                 % [1 -1]
%
%   Voir aussi CONNECT, SS, APPEND, FEEDBACK.
    if nargin < 2 || isempty(largeur)
        largeur = 1;
    end
    texte = char(expression);
    egal = strfind(texte, '=');
    if isempty(egal)
        error('Control:sumblk:NoEqual', ...
              'A summing junction is written like ''e = r - y''.');
    end
    sortie = strtrim(texte(1:egal(1)-1));
    droite = strtrim(texte(egal(1)+1:end));
    if isempty(sortie)
        error('Control:sumblk:NoOutput', 'The left side must name the output.');
    end

    % Le membre de droite : une somme de termes signés, avec gain.
    termes = {};
    signes = [];
    gains = [];
    courant = '';
    signe = 1;
    for k = 1:numel(droite)
        c = droite(k);
        if (c == '+' || c == '-') && ~isempty(strtrim(courant))
            [nom, gain] = decouperTerme(courant);
            termes{end+1} = nom;      %#ok<AGROW>
            signes(end+1) = signe;    %#ok<AGROW>
            gains(end+1) = gain;      %#ok<AGROW>
            courant = '';
            signe = 1;
            if c == '-'
                signe = -1;
            end
        elseif c == '-' && isempty(strtrim(courant))
            signe = -signe;
        elseif c == '+' && isempty(strtrim(courant))
            % un plus de tête : rien à faire
        else
            courant = [courant c];    %#ok<AGROW>
        end
    end
    if ~isempty(strtrim(courant))
        [nom, gain] = decouperTerme(courant);
        termes{end+1} = nom;
        signes(end+1) = signe;
        gains(end+1) = gain;
    end
    if isempty(termes)
        error('Control:sumblk:NoInput', 'The right side must name at least one input.');
    end

    coefficients = signes .* gains;
    D = kron(coefficients, eye(largeur));
    D(D == 0) = 0;      % pas de zéro négatif dans l'affichage
    S = ss(zeros(0, 0), zeros(0, numel(termes) * largeur), ...
           zeros(largeur, 0), D);
    S.OutputName = matlibre_noms_voies(sortie, largeur);
    entrees = {};
    for k = 1:numel(termes)
        noms = matlibre_noms_voies(termes{k}, largeur);
        entrees = [entrees; noms];    %#ok<AGROW>
    end
    S.InputName = entrees;
end

function [nom, gain] = decouperTerme(terme)
%DECOUPERTERME Un terme « 2*y » : son nom et son gain.
    terme = strtrim(terme);
    etoile = strfind(terme, '*');
    gain = 1;
    if ~isempty(etoile)
        gain = str2double(terme(1:etoile(1)-1));
        terme = strtrim(terme(etoile(1)+1:end));
        if isnan(gain)
            error('Control:sumblk:BadGain', 'The gain of a term must be a number.');
        end
    end
    nom = terme;
end
