function r = usubs(objet, varargin)
%USUBS Fixe des paramètres incertains.
%   R = USUBS(U,'nom',VALEUR,...) remplace les paramètres nommés par les
%   valeurs données. Les paramètres non nommés gardent leur valeur
%   nominale, si bien que le résultat est toujours un objet certain :
%   une matrice pour un UMAT, un modèle SS pour un USS.
%
%   R = USUBS(U,STRUCTURE) prend les valeurs dans les champs d'une
%   structure — celle que rend USAMPLE, par exemple.
%
%   R = USUBS(U,'nominal') donne à tous leur valeur nominale, comme
%   GETNOMINAL.
%
%   Une valeur hors des bornes du paramètre est acceptée : USUBS ne
%   juge pas, il substitue. C'est ce qui permet de regarder ce que
%   deviendrait le modèle un peu au-delà de ce qu'on a déclaré.
%
%   Exemples :
%      m = ureal('m', 1, 'Percentage', 20);
%      k = ureal('k', 4, 'Range', [3 5]);
%      G = uss([0 1; -k/m -0.2/m], [0; 1/m], [1 0], 0);
%      pole(usubs(G, 'k', 5, 'm', 0.8))'
%      bode(usubs(G, 'k', 3));
%
%      [~, tirage] = usample(G);
%      usubs(G, tirage)
%
%   Voir aussi USAMPLE, GETNOMINAL, UREAL, UMAT, USS, WCGAIN.
    [parametres, evaluer] = matlibre_incertitudes(objet);
    valeurs = umat.valeursNominales(parametres);
    if numel(varargin) == 1 && isstruct(varargin{1})
        champs = fieldnames(varargin{1});
        for k = 1:numel(champs)
            valeurs.(champs{k}) = varargin{1}.(champs{k});
        end
    elseif numel(varargin) == 1 && (ischar(varargin{1}) || isstring(varargin{1}))
        if ~strcmpi(char(varargin{1}), 'nominal')
            error('Robust:usubs:BadOption', ...
                  'USUBS takes name-value pairs, a structure, or ''nominal''.');
        end
    else
        k = 1;
        while k + 1 <= numel(varargin)
            valeurs.(char(varargin{k})) = varargin{k + 1};
            k = k + 2;
        end
        if k <= numel(varargin)
            error('Robust:usubs:OddArguments', ...
                  'USUBS needs a value for every name.');
        end
    end
    r = evaluer(valeurs);
end
