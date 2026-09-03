function fis = addOutput(fis, intervalle, varargin)
%ADDOUTPUT Ajoute une variable de sortie à un système flou.
%   FIS = ADDOUTPUT(FIS,[MIN MAX]) ajoute une sortie nommée « outputN ».
%   Les options sont celles d'ADDINPUT : 'Name', 'NumMFs', 'MFType'.
%
%   Exemple :
%      fis = mamfis('Name', 'exemple');
%      fis = addOutput(fis, [0 30], 'Name', 'pourboire', 'NumMFs', 3);
%
%   Voir aussi ADDINPUT, ADDMF, ADDRULE, REMOVEOUTPUT, ADDVAR.
    if nargin < 2 || isempty(intervalle), intervalle = [0 1]; end
    fis = ajouterVariable(fis, false, intervalle, varargin{:});
end
