function fis = addMF(fis, variable, type, parametres, varargin)
%ADDMF Ajoute une modalité à une variable, par son nom.
%   FIS = ADDMF(FIS,NOM,TYPE,PARAMS) ajoute à la variable nommée NOM —
%   entrée ou sortie — une fonction d'appartenance de forme TYPE.
%   FIS = ADDMF(...,'Name',N) la nomme ; sans cela elle s'appelle « mfK ».
%
%   C'est l'écriture moderne d'ADDMF à quatre arguments, qui désignait la
%   variable par son genre et son rang. Les deux formes coexistent : si
%   le deuxième argument est 'input' ou 'output', c'est l'ancienne.
%
%   Exemple :
%      fis = addInput(mamfis, [0 10], 'Name', 'service');
%      fis = addMF(fis, 'service', 'trimf', [0 0 5], 'Name', 'faible');
%      fis.entrees{1}.mf{1}.nom       % 'faible'
%
%   Voir aussi ADDINPUT, ADDOUTPUT, ADDRULE, REMOVEMF, EVALMF.
    if ischar(variable) || isstring(variable)
        mot = lower(char(variable));
        if any(strcmp(mot, {'input', 'in', 'output', 'out'}))
            % Ancienne forme : ADDMF(FIS,GENRE,INDICE,NOM,TYPE,PARAMS).
            fis = addmf(fis, variable, type, parametres, varargin{:});
            return
        end
    end
    [entree, indice] = trouverVariable(fis, variable);
    variables = variablesDe(fis, entree);
    nom = sprintf('mf%d', numel(variables{indice}.mf) + 1);
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'name', nom = char(varargin{k+1});
            otherwise
                error('fuzzy:addMF:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if entree
        genre = 'input';
    else
        genre = 'output';
    end
    fis = addmf(fis, genre, indice, nom, lower(char(type)), double(parametres));
end
