function description = deploytool(script)
%DEPLOYTOOL Décrit le paquet de distribution d'un script.
    description = struct();
    description.script = script;
    description.interpreteur = 'matlibre';
    description.toolboxes = matlabroot();
    description.remarque = ['Le programme produit appelle l''interpreteur ' ...
                            'MatLibre ; il n''est pas autonome au sens binaire.'];
end
