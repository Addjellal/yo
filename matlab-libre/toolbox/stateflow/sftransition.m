function machine = sftransition(machine, depuis, vers, garde, action)
%SFTRANSITION Ajoute une transition gardée.
%   GARDE est une poignée @(contexte,entree) qui rend vrai ou faux.
%   ACTION, facultative, est une poignée @(contexte) qui rend le contexte.
    if nargin < 5, action = []; end
    t = struct();
    t.depuis = depuis;
    t.vers = vers;
    t.garde = garde;
    t.action = action;
    machine.transitions{end+1} = t;
end
