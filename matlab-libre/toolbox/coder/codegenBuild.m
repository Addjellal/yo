function [ok, message, sortie] = codegenBuild(nomFonction, varargin)
%CODEGENBUILD Génère le C puis le compile avec le compilateur du système.
%   [OK,MESSAGE] = CODEGENBUILD('f') écrit f.c et f.h dans un dossier
%   temporaire puis les compile en objet.
%   CODEGENBUILD('f','-args',{...},'-d',DOSSIER) accepte les mêmes options
%   que CODEGEN, plus '-exe' pour produire un exécutable de démonstration.
    dossier = tempdir();
    executable = false;
    options = {};
    k = 1;
    while k <= numel(varargin)
        courant = varargin{k};
        if ~(ischar(courant) || isstring(courant))
            % La valeur d'une option — le tableau d'exemples de « -args »,
            % par exemple — passe telle quelle a codegen. Sans ce test,
            % char() d'une cellule levait « Conversion to double from cell
            % is not possible » et codegenBuild('f','-args',{0}) etait
            % inutilisable.
            options{end + 1} = courant;                       %#ok<AGROW>
            k = k + 1;
            continue
        end
        option = char(courant);
        switch lower(option)
            case '-d'
                dossier = char(varargin{k + 1});
                k = k + 2;
            case '-exe'
                executable = true;
                k = k + 1;
            otherwise
                options{end + 1} = courant;                   %#ok<AGROW>
                k = k + 1;
        end
    end
    if executable
        options = [options, {'-config', 'exe'}];
    end
    sortie = codegen(nomFonction, options{:}, '-d', dossier);
    % Le compilateur n'est pas toujours « cc » : MinGW n'installe que gcc.
    [compilateur, famille] = compilateurC();
    if isempty(compilateur)
        sortie.cible = '';
        sortie.commande = '';
        ok = false;
        if strcmp(famille, 'msvc')
            message = ['Visual Studio (cl) a ete trouve, mais codegenBuild ne sait ' ...
                       'appeler qu''un compilateur de la famille gcc. Installez ' ...
                       'MinGW-w64, ou compilez le C produit a la main.'];
        else
            message = ['Aucun compilateur C n''a ete trouve (cc, gcc, clang). ' ...
                       'Le C a tout de meme ete ecrit.'];
        end
        return
    end
    if executable
        % gcc ajoute « .exe » sous Windows quand la cible n'a pas
        % d'extension : sans cela, le chemin rendu ne designerait aucun
        % fichier.
        if ispc()
            cible = fullfile(dossier, [nomFonction '.exe']);
        else
            cible = fullfile(dossier, nomFonction);
        end
        commande = sprintf('%s -O2 -o %s %s -lm', compilateur, cible, sortie.fichierSource);
    else
        cible = fullfile(dossier, [nomFonction '.o']);
        commande = sprintf('%s -c -O2 -o %s %s', compilateur, cible, sortie.fichierSource);
    end
    [code, message] = system(commande);
    ok = (code == 0);
    sortie.cible = cible;
    sortie.commande = commande;
end
