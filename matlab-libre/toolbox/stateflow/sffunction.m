function machine = sffunction(machine, nom, fonction)
%SFFUNCTION Ajoute une fonction à la machine.
%   MACHINE = SFFUNCTION(MACHINE,NOM,F) donne à la machine une fonction,
%   comme une fonction graphique ou une fonction MATLAB d'un diagramme
%   Stateflow : ses gardes et ses actions écrites en texte l'appellent par
%   son nom. F est une poignée de fonction — @(x) 2*x, ou @mafonction.
%
%   Exemple :
%      m = sfchart('chauffe');
%      m = sffunction(m, 'consigne', @(h) 18 + 2 * (h >= 8 && h < 22));
%      m = sfstate(m, 'regle', 'du: c = consigne(u);');
%      [~, c] = sfrun(m, [7 9]);
%      c.c                          % 20
%
%   Voir aussi SFTRUTHTABLE, SFSTATE, SFTRANSITION.
    nom = char(nom);
    if ~isvarname(nom)
        error('Stateflow:NomInvalide', 'Function name ''%s'' is not a valid name.', nom);
    end
    if ~isa(fonction, 'function_handle')
        error('Stateflow:FonctionInvalide', ...
              'Function ''%s'' must be given as a function handle, @(x) ... or @name.', nom);
    end
    if ~isfield(machine, 'fonctions')
        machine.fonctions = struct();
    end
    machine.fonctions.(nom) = fonction;
end
