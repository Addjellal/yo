function varargout = sorties()
%SORTIES Une fonction de paquet d'essai : elle dit combien de sorties on lui demande.
%   Sert à TEST_CLASSES : appelée en instruction, elle voit nargout valoir
%   0 et le range dans la variable de base sortiesEssai.
    assignin('base', 'sortiesEssai', nargout);
    for k = 1:nargout
        varargout{k} = k;
    end
end
