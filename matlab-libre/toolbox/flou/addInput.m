function fis = addInput(fis, intervalle, varargin)
%ADDINPUT Ajoute une variable d'entrée à un système flou.
%   FIS = ADDINPUT(FIS) ajoute une entrée nommée « inputN », d'intervalle
%   [0 1].
%   FIS = ADDINPUT(FIS,[MIN MAX]) donne son intervalle.
%   FIS = ADDINPUT(FIS,...,'Name',NOM) la nomme, 'NumMFs',N lui pose N
%   modalités régulièrement réparties, 'MFType',T en choisit la forme
%   ('trimf' par défaut, 'trapmf' et 'gaussmf' acceptées).
%
%   C'est l'écriture moderne d'ADDVAR ; les deux mènent au même système.
%
%   Exemple :
%      fis = mamfis('Name', 'exemple');
%      fis = addInput(fis, [0 10], 'Name', 'service', 'NumMFs', 3);
%      numel(fis.entrees{1}.mf)       % 3
%
%   Voir aussi ADDOUTPUT, ADDMF, ADDRULE, REMOVEINPUT, ADDVAR.
    if nargin < 2 || isempty(intervalle), intervalle = [0 1]; end
    fis = ajouterVariable(fis, true, intervalle, varargin{:});
end
