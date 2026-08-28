function sortie = codegen(varargin)
%CODEGEN Traduit une fonction MATLAB en C.
%   CODEGEN('f') traduit f en supposant des entrées scalaires double.
%   CODEGEN('f','-args',{...}) donne le type et la taille de chaque entrée :
%   chaque case du tableau est un exemple de valeur, dont la classe et les
%   dimensions décident du C produit.
%
%   Options, reprises de MATLAB Coder :
%      '-args' EXEMPLES   types et tailles des entrées
%      '-o' NOM           nom de base des fichiers écrits
%      '-d' DOSSIER       dossier de sortie (défaut : le dossier courant)
%      '-nargout' N       nombre de sorties à produire
%      '-lang:c'          langage C (défaut)
%      '-lang:c++'        langage C++, en-tête extern "C"
%      '-config' MODE     'lib' (défaut), 'exe' ajoute un main de démonstration
%      '-report'          rend la structure du résultat au lieu d'écrire
%      '-c'               n'écrit que les sources, sans compiler
%
%   Le C produit n'alloue rien : les tableaux sont de taille fixe, rangés
%   par colonnes comme en MATLAB, et les conversions entières saturent.
%
%   Les entrées complexes se déclarent avec COMPLEX : la classe et la
%   complexité de l'exemple décident du C produit. Un complexe devient une
%   structure matlibre_cplx de deux double, définie dans l'en-tête.
%
%   Exemple :
%      codegen('carreDeTest', '-args', {0}, '-report')
%      codegen('produitTest', '-args', {zeros(3,3), zeros(3,1)})
%      codegen('filtreTest',  '-args', {complex(zeros(1,8))})
%
%   Voir aussi CODEGENBUILD, CODER.TYPEOF.
    if isempty(varargin)
        error('coder:codegen:noFunction', 'Specify the name of a function to translate.');
    end
    nom = char(varargin{1});
    exemples = {};
    dossier = pwd();
    base = '';
    nSorties = 1;
    langage = 'c';
    configuration = 'lib';
    rapport = false;
    ecrire = true;
    k = 2;
    while k <= numel(varargin)
        option = char(varargin{k});
        switch lower(option)
            case '-args'
                exemples = varargin{k + 1};
                if ~iscell(exemples), exemples = {exemples}; end
                k = k + 2;
            case '-o'
                base = char(varargin{k + 1});
                k = k + 2;
            case '-d'
                dossier = char(varargin{k + 1});
                k = k + 2;
            case '-nargout'
                nSorties = varargin{k + 1};
                k = k + 2;
            case '-config'
                configuration = char(varargin{k + 1});
                k = k + 2;
            case '-lang:c'
                langage = 'c'; k = k + 1;
            case {'-lang:c++', '-lang:cpp'}
                langage = 'c++'; k = k + 1;
            case '-report'
                rapport = true; ecrire = false; k = k + 1;
            case '-c'
                ecrire = true; k = k + 1;
            otherwise
                error('coder:codegen:unknownOption', ...
                      'Unrecognized option ''%s''.', option);
        end
    end
    if isempty(exemples)
        % Sans -args, on suppose des scalaires double : le nombre d'entrées
        % vient de la signature de la fonction.
        n = nargin_de(nom);
        exemples = cell(1, n);
        for i = 1:n, exemples{i} = 0; end
    end
    options = struct('nargout', nSorties, 'langage', langage, 'prefixe', '', ...
                     'principal', strcmpi(configuration, 'exe'));
    resultat = matlibre_codegen(nom, exemples, options);
    if isempty(base), base = resultat.fonctions{1}; end
    resultat.fichierSource = fullfile(dossier, [base '.' langageExtension(langage)]);
    resultat.fichierEntete = fullfile(dossier, [base '.h']);
    if ecrire
        ecrireFichier(resultat.fichierSource, resultat.source);
        ecrireFichier(resultat.fichierEntete, resultat.entete);
    end
    if rapport || nargout > 0
        sortie = resultat;
    else
        fprintf('Code generation successful: %s\n', resultat.fichierSource);
    end
end

function e = langageExtension(langage)
    if strcmp(langage, 'c++'), e = 'cpp'; else, e = 'c'; end
end

function ecrireFichier(chemin, texte)
    f = fopen(chemin, 'w');
    if f < 0
        error('coder:codegen:cannotWrite', 'Unable to write ''%s''.', chemin);
    end
    fprintf(f, '%s', texte);
    fclose(f);
end

function n = nargin_de(nom)
    chemin = which(nom);
    if isempty(chemin)
        error('coder:codegen:notFound', 'Function ''%s'' not found.', nom);
    end
    texte = fileread(chemin);
    lignes = strsplit(texte, sprintf('\n'));
    n = 0;
    for k = 1:numel(lignes)
        ligne = strtrim(lignes{k});
        if strncmp(ligne, 'function', 8)
            ouvrante = strfind(ligne, '(');
            fermante = strfind(ligne, ')');
            if isempty(ouvrante), n = 0; return, end
            liste = strtrim(ligne(ouvrante(1) + 1:fermante(end) - 1));
            if isempty(liste), n = 0; return, end
            n = numel(strsplit(liste, ','));
            return
        end
    end
end
