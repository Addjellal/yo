function [nom, famille] = compilateurC()
%COMPILATEURC Trouve un compilateur C sur la machine.
%   NOM = COMPILATEURC() rend le nom de l'exécutable à appeler, ou une
%   chaîne vide si aucun compilateur n'est trouvé.
%
%   [NOM,FAMILLE] = COMPILATEURC() rend en plus la famille d'options :
%   'gcc' pour cc, gcc et clang, qui partagent la ligne de commande d'Unix.
%
%   Les candidats sont essayés dans l'ordre : cc, gcc, clang. Sous Windows,
%   MinGW installe gcc mais pas cc, d'où l'essai des trois — c'est ce qui
%   faisait sauter la compilation du C produit dans les tests.
%
%   Visual Studio (cl) n'est pas encore géré : sa ligne de commande n'a
%   rien de commun avec celle d'Unix. Il est détecté et signalé plutôt que
%   d'être appelé avec des options qu'il ne comprend pas.
%
%   Exemple :
%      compilateur = compilateurC();
%      if isempty(compilateur)
%          disp('pas de compilateur C');
%      end
%
%   Voir aussi CODEGEN, CODEGENBUILD.
    nom = '';
    famille = '';
    for candidat = {'cc', 'gcc', 'clang'}
        essai = candidat{1};
        [code, ~] = system([essai ' --version']);
        if code == 0
            nom = essai;
            famille = 'gcc';
            return
        end
    end
    % cl n'a pas d'option --version ; « cl /? » rend 0 quand il est là.
    [code, ~] = system('cl /?');
    if code == 0
        famille = 'msvc';
    end
end
