function r = rewrite(f, cible)
%REWRITE Réécrit une expression avec d'autres fonctions.
%   REWRITE(F,CIBLE) remplace les fonctions de F par des équivalents
%   exprimés à l'aide de CIBLE. Les réécritures reconnues :
%
%      'exp'    sin, cos, tan, sinh, cosh, tanh en exponentielles
%      'sincos' tan en sinus sur cosinus
%      'tan'    sin et cos en tangente de l'arc moitié
%      'log'    asin, acos, atan en logarithmes
%      'sqrt'   ce qui s'écrit avec une racine
%
%   Une réécriture ne change pas la valeur : elle change la forme, ce qui
%   permet à une simplification de voir ce qu'elle ne voyait pas. C'est
%   son seul emploi, et c'est pour cela qu'on vérifie une réécriture en
%   comparant les deux formes en quelques points plutôt qu'en les lisant.
%
%   Exemple :
%      syms x
%      e = rewrite(sin(x), 'exp');
%      abs(double(subs(e, x, 1)) - sin(1)) < 1e-12
%
%   Voir aussi SIMPLIFY, EXPAND, COLLECT, SUBS.
    f = sym(f);
    cible = lower(char(cible));
    connues = {'exp', 'sincos', 'tan', 'log', 'sqrt'};
    if ~any(strcmp(cible, connues))
        error('symbolic:rewrite:cible', ...
              'Cible inconnue : ''%s''. Employez %s.', cible, strjoin(connues, ', '));
    end
    r = sym(matlibre_sym_reduire(matlibre_sym_reecrire(f.arbre, cible)));
end
