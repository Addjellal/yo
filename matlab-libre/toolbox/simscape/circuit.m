function c = circuit(nom)
%CIRCUIT Crée un circuit vide.
%   C = CIRCUIT(NOM) rend un circuit sans composant. Le nœud 0 est la
%   masse, et les autres se numérotent librement : le circuit compte comme
%   nœuds tous ceux qu'un composant nomme.
%
%   Décrire un circuit, non les équations qui le régissent : c'est le
%   propos. On pose des composants entre des nœuds, et SOLVEDC ou
%   SOLVETRANSIENT écrivent et résolvent le système.
%
%   Exemple :
%      c = circuit('diviseur');
%      c = addVoltageSource(c, 1, 0, 10);
%      c = addResistor(c, 1, 2, 1000);
%      c = addResistor(c, 2, 0, 2000);
%      v = solveDC(c)                  % v(2) = 6,667 V
%
%   Voir aussi ADDRESISTOR, ADDCAPACITOR, ADDINDUCTOR, ADDVOLTAGESOURCE,
%   ADDCURRENTSOURCE, SOLVEDC, SOLVETRANSIENT.
    c = struct();
    c.nom = nom;
    c.composants = {};
    c.noeuds = 0;
end
