function r = commandeDEssai(varargin)
%COMMANDEDESSAI Rend ses arguments joints, pour verifier la syntaxe commande.
    r = strjoin(varargin, '|');
end
