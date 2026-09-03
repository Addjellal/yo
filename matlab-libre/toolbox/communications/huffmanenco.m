function code = huffmanenco(signal, dictionnaire)
%HUFFMANENCO Codage de Huffman.
%   CODE = HUFFMANENCO(SIG,DICT) remplace chaque symbole de SIG par son
%   mot de code, tiré du dictionnaire que rend HUFFMANDICT, et met le
%   tout bout à bout.
%
%   Le code étant préfixe — aucun mot n'en commence un autre —, la suite
%   se décode sans séparateur : c'est ce qui fait tenir la compression.
%
%   Exemple :
%      d = huffmandict([1 2 3], [0.5 0.25 0.25]);
%      code = huffmanenco([1 2 1 3], d);
%      isequal(huffmandeco(code, d), [1 2 1 3])   % vrai
%
%   Voir aussi HUFFMANDICT, HUFFMANDECO.
    signal = signal(:).';
    code = [];
    for k = 1:numel(signal)
        indice = trouverSymbole(dictionnaire, signal(k));
        code = [code, dictionnaire{indice, 2}];   %#ok<AGROW>
    end
end

function indice = trouverSymbole(dictionnaire, symbole)
    for k = 1:size(dictionnaire, 1)
        candidat = dictionnaire{k, 1};
        if ischar(candidat) || isstring(candidat)
            if (ischar(symbole) || isstring(symbole)) && strcmp(char(candidat), char(symbole))
                indice = k;
                return
            end
        elseif isnumeric(symbole) && candidat == symbole
            indice = k;
            return
        end
    end
    error('comm:huffmanenco:Symbole', ...
          'Un symbole du signal n''est pas dans le dictionnaire.');
end
