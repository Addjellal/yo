function texte = plotfis(fis)
%PLOTFIS Vue d'ensemble d'un système d'inférence floue.
%   PLOTFIS(FIS) écrit la structure du système : ses entrées avec leurs
%   modalités, ses sorties, et le nombre de règles qui les relient.
%   T = PLOTFIS(FIS) rend ce texte au lieu de l'afficher.
%
%   Exemple :
%      fis = mamfis('Name', 'pilote');
%      fis = addInput(fis, [0 10], 'Name', 'erreur');
%      fis = addMF(fis, 'erreur', 'trimf', [0 0 5], 'Name', 'petite');
%      fis = addMF(fis, 'erreur', 'trimf', [5 10 10], 'Name', 'grande');
%      fis = addOutput(fis, [0 1], 'Name', 'commande');
%      fis = addMF(fis, 'commande', 'trimf', [0 0 0.5], 'Name', 'faible');
%      fis = addMF(fis, 'commande', 'trimf', [0.5 1 1], 'Name', 'forte');
%      fis = addRule(fis, [1 1 1 1; 2 2 1 1]);
%      plotfis(fis)
%
%   Voir aussi PLOTMF, SHOWRULE, GETFIS.
    lignes = {};
    lignes{end+1} = sprintf('%s  (%s, %d règles)', fis.nom, fis.type, size(fis.regles, 1));
    lignes{end+1} = 'Entrées :';
    for k = 1:numel(fis.entrees)
        lignes{end+1} = decrireVariable(fis.entrees{k}, k);          %#ok<AGROW>
    end
    lignes{end+1} = 'Sorties :';
    for k = 1:numel(fis.sorties)
        lignes{end+1} = decrireVariable(fis.sorties{k}, k);          %#ok<AGROW>
    end
    resultat = strjoin(lignes, sprintf('\n'));
    if nargout > 0
        texte = resultat;
    else
        disp(resultat);
    end
end

function ligne = decrireVariable(v, k)
    noms = cell(1, numel(v.mf));
    for j = 1:numel(v.mf)
        noms{j} = v.mf{j}.nom;
    end
    ligne = sprintf('  %d. %-12s [%g %g]  {%s}', k, v.nom, ...
                    v.intervalle(1), v.intervalle(2), strjoin(noms, ', '));
end
