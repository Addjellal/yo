function [F1, F2, mode, reste] = matlibre_ondelette_arguments(arguments, genre, nomFonction)
%MATLIBRE_ONDELETTE_ARGUMENTS Ondelette et mode d'une transformée discrète.
%   [F1,F2,MODE,RESTE] = MATLIBRE_ONDELETTE_ARGUMENTS(ARGS,GENRE,NOM) lit,
%   au début de ARGS, soit un nom d'ondelette, soit deux filtres ; GENRE
%   vaut 'd' (filtres de décomposition Lo_D, Hi_D) ou 'r' (reconstruction
%   Lo_R, Hi_R). L'option 'mode',MODE est retirée où qu'elle soit ; à
%   défaut, MODE est celui de DWTMODE. RESTE garde les autres arguments.
    if isempty(arguments)
        error('Wavelet:FunctionInput:NotEnoughArgs', ...
              '%s : il faut un nom d''ondelette ou deux filtres.', upper(nomFonction));
    end
    premier = arguments{1};
    if ischar(premier) || (isstring(premier) && isscalar(premier))
        [Lo_D, Hi_D, Lo_R, Hi_R] = wfilters(char(premier));
        if genre == 'd'
            F1 = Lo_D;
            F2 = Hi_D;
        else
            F1 = Lo_R;
            F2 = Hi_R;
        end
        k = 2;
    else
        if numel(arguments) < 2 || ~isnumeric(arguments{2})
            error('Wavelet:FunctionInput:NotEnoughArgs', ...
                  '%s : les filtres vont par deux, passe-bas puis passe-haut.', ...
                  upper(nomFonction));
        end
        F1 = arguments{1};
        F2 = arguments{2};
        k = 3;
    end
    F1 = double(F1(:)).';
    F2 = double(F2(:)).';
    if numel(F1) ~= numel(F2)
        error('Wavelet:FunctionInput:FilterLength', ...
              '%s : les deux filtres ont la même longueur.', upper(nomFonction));
    end
    mode = dwtmode('status', 'nodisp');
    reste = {};
    while k <= numel(arguments)
        a = arguments{k};
        if (ischar(a) || (isstring(a) && isscalar(a))) && strcmpi(char(a), 'mode') && ...
                k < numel(arguments)
            mode = matlibre_mode_ondelette(arguments{k + 1});
            k = k + 2;
        else
            reste{end + 1} = a; %#ok<AGROW>
            k = k + 1;
        end
    end
end
