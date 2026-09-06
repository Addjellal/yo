function machine = sfchart(nom)
%SFCHART Crée une machine à états vide.
%   MACHINE = SFCHART(NOM) rend une machine sans état ni transition. Le
%   premier état ajouté devient l'état initial.
%
%   Un système à modes ne se décrit pas par une équation mais par un
%   automate : des états, et des transitions gardées qui disent quand on
%   passe de l'un à l'autre. Toute la logique tient dans les gardes.
%
%   Ce qui distingue un automate d'une fonction : la même entrée n'a pas
%   le même effet selon l'état. C'est cette mémoire qui permet de compter,
%   de reconnaître une suite, ou de tenir un mode.
%
%   Exemple :
%      m = sfchart('tourniquet');
%      m = sfstate(m, 'verrouille');
%      m = sfstate(m, 'ouvert');
%      m = sftransition(m, 'verrouille', 'ouvert', @(c,e) strcmp(e,'piece'));
%      m = sftransition(m, 'ouvert', 'verrouille', @(c,e) strcmp(e,'pousse'));
%      sfrun(m, {'pousse', 'piece', 'pousse'})
%
%   Voir aussi SFSTATE, SFTRANSITION, SFRUN.
    machine = struct();
    machine.nom = nom;
    machine.etats = {};
    machine.transitions = {};
    machine.initial = '';
end
