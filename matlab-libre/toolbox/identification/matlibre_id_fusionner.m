function z = matlibre_id_fusionner(jeux)
%MATLIBRE_ID_FUSIONNER Assemble des jeux en autant d'expériences.
%   Z = MATLIBRE_ID_FUSIONNER(JEUX) range les jeux donnés dans un même
%   objet, chacun restant une expérience distincte.
%
%   Estimer sur plusieurs expériences à la fois vaut mieux que d'estimer
%   sur chacune puis de moyenner : les données se joignent, mais pas les
%   suites temporelles — le bruit d'une expérience ne prédit rien de la
%   suivante, et les concaténer bout à bout fabriquerait une transition
%   qui n'a pas eu lieu.
%
%   Exemple :
%      z = merge(iddata((1:5)'), iddata((6:10)'));
%      nexp(z)      % 2
%
%   Voir aussi IDDATA, GETEXP.
    sorties = {};
    entrees = {};
    noms = {};
    modele = [];
    for k = 1:numel(jeux)
        courant = jeux{k};
        if ~isa(courant, 'iddata')
            continue
        end
        if isempty(modele)
            modele = courant;
        end
        for e = 1:matlibre_id_nombre_experiences(courant)
            sorties{end + 1} = matlibre_id_bloc(courant.OutputData, e);   %#ok<AGROW>
            if isempty(courant.InputData)
                entrees{end + 1} = [];                                    %#ok<AGROW>
            else
                entrees{end + 1} = matlibre_id_bloc(courant.InputData, e); %#ok<AGROW>
            end
            noms{end + 1} = sprintf('Exp%d', numel(sorties));             %#ok<AGROW>
        end
    end
    z = modele;
    z.OutputData = sorties;
    if all(cellfun(@isempty, entrees))
        z.InputData = [];
    else
        z.InputData = entrees;
    end
    z.ExperimentName = noms;
end
