function [gauche, droite] = matlibre_sym_defaire(gauche, droite, nom)
%MATLIBRE_SYM_DEFAIRE Défait une opération autour de l'inconnue.
%   Applique aux deux membres l'opération inverse de celle qui coiffe le
%   membre de gauche, de sorte que l'inconnue s'en trouve un cran moins
%   enveloppée. Un pas de ce que fait ISOLATE.
%
%   La branche qui ne porte pas l'inconnue passe à droite ; celle qui la
%   porte reste à gauche. C'est ce choix, et lui seul, qui fait avancer :
%   sans lui on tournerait en rond.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [g, d] = matlibre_sym_defaire({'+', {'var','x'}, {'num',3}}, ...
%                                    {'num', 0}, 'x');
%      char(sym(g))                    % x
%      char(sym(matlibre_sym_reduire(d)))   % -3
%
%   Voir aussi ISOLATE.
    operateur = gauche{1};
    switch operateur
        case {'+', '-', '*', '/'}
            aGauche = matlibre_sym_compter(gauche{2}, nom) > 0;
            porteur = gauche{2 + double(~aGauche)};
            autre = gauche{2 + double(aGauche)};
            switch operateur
                case '+', droite = symsub(droite, autre);
                case '*', droite = symdiv(droite, autre);
                case '-'
                    if aGauche
                        droite = symadd(droite, autre);      % x - a = d
                    else
                        droite = symsub(autre, droite);      % a - x = d
                    end
                case '/'
                    if aGauche
                        droite = symmul(droite, autre);      % x / a = d
                    else
                        droite = symdiv(autre, droite);      % a / x = d
                    end
            end
            gauche = porteur;
        case '^'
            exposant = gauche{3};
            if matlibre_sym_compter(gauche{2}, nom) > 0
                % x^n = d donne x = d^(1/n).
                droite = sympow(droite, symdiv(symnum(1), exposant));
            else
                % a^x = d donne x = log(d)/log(a).
                droite = symdiv({'log', droite}, {'log', gauche{2}});
            end
            gauche = gauche{2 + double(matlibre_sym_compter(gauche{2}, nom) == 0)};
        case 'sin',  droite = {'asin', droite};  gauche = gauche{2};
        case 'cos',  droite = {'acos', droite};  gauche = gauche{2};
        case 'tan',  droite = {'atan', droite};  gauche = gauche{2};
        case 'exp',  droite = {'log', droite};   gauche = gauche{2};
        case 'log',  droite = {'exp', droite};   gauche = gauche{2};
        case 'sqrt', droite = sympow(droite, symnum(2)); gauche = gauche{2};
        otherwise
            error('symbolic:isolate:operation', ...
                  'ISOLATE ne sait pas defaire ''%s''.', operateur);
    end
end
