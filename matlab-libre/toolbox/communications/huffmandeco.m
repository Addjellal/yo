function signal = huffmandeco(code, dictionnaire)
%HUFFMANDECO Décodage de Huffman.
%   SIG = HUFFMANDECO(CODE,DICT) retrouve les symboles à partir de la
%   suite de chiffres CODE et du dictionnaire DICT.
%
%   Le décodage lit les chiffres un à un jusqu'à reconnaître un mot du
%   dictionnaire : le code étant préfixe, aucune ambiguïté n'est
%   possible. Une suite qui ne se décompose pas en mots est refusée
%   plutôt que tronquée en silence.
%
%   Exemple :
%      d = huffmandict([1 2 3], [0.5 0.25 0.25]);
%      huffmandeco(huffmanenco([1 2 3 1], d), d)   % [1 2 3 1]
%
%   Voir aussi HUFFMANDICT, HUFFMANENCO.
    code = double(code(:)).';
    signal = {};
    numerique = true;
    for k = 1:size(dictionnaire, 1)
        if ischar(dictionnaire{k, 1}) || isstring(dictionnaire{k, 1})
            numerique = false;
        end
    end
    debut = 1;
    while debut <= numel(code)
        trouve = 0;
        for k = 1:size(dictionnaire, 1)
            mot = dictionnaire{k, 2};
            fin = debut + numel(mot) - 1;
            if fin <= numel(code) && isequal(code(debut:fin), mot)
                trouve = k;
                break
            end
        end
        if trouve == 0
            error('comm:huffmandeco:Incomplet', ...
                  ['La suite ne se décompose pas en mots du dictionnaire, ' ...
                   'à partir du chiffre %d.'], debut);
        end
        signal{end + 1} = dictionnaire{trouve, 1};   %#ok<AGROW>
        debut = debut + numel(dictionnaire{trouve, 2});
    end
    if numerique
        signal = cell2mat(signal);
    end
end
