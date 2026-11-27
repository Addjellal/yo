function io = linio(bloc, port, type, ouverture, element)
%LINIO Un point d'analyse, pour LINEARIZE.
%   IO = LINIO(BLOC,PORT,TYPE) désigne le signal qui part du port de
%   sortie PORT du bloc BLOC — son chemin 'modele/bloc', ou sa poignée —
%   et dit ce que LINEARIZE y fait :
%     'input'            une entrée : une perturbation ajoutée au signal
%     'output'           une sortie : le signal, mesuré
%     'loopbreak'        une coupure : la boucle est ouverte ici
%     'openinput'        une coupure, puis une entrée
%     'openoutput'       une sortie, puis une coupure
%     'looptransfer'     une sortie, une coupure, puis une entrée : le
%                        transfert de boucle, avec le signe du schéma
%     'sensitivity'      une entrée, puis une sortie
%     'compsensitivity'  une sortie, puis une entrée
%   LINIO(BLOC,PORT) pose une entrée.
%
%   IO est une structure : Active ('on'), Block, OpenLoop, PortNumber,
%   Type, BusElement et Description. Plusieurs points se rangent en
%   vecteur : IO(1) = LINIO(...); IO(2) = LINIO(...). OpenLoop réglé sur
%   'on' coupe la boucle au point — d'une 'input', il fait une
%   'openinput' — ; un type qui porte déjà sa coupure la garde quel que
%   soit OpenLoop : pour la retirer, on change Type. Active réglé sur
%   'off' fait ignorer le point.
%
%   L'ancienne écriture est comprise : LINIO(BLOC,PORT,T,OUVERTURE), T
%   valant 'in', 'out', 'inout' (sensitivity), 'outin' (compsensitivity)
%   ou 'none', et OUVERTURE 'on' ou 'off'.
%
%   Exemple :
%      io(1) = linio('boucle/consigne', 1, 'input');
%      io(2) = linio('boucle/procede', 1, 'openoutput');
%      io(2).Type                               % 'openoutput'
%      io(2).OpenLoop                           % 'on'
%
%   Voir aussi LINEARIZE, LINMOD, DLINMOD.
    if nargin < 2
        error('Simulink:Linearize:LinioArguments', ...
              'LINIO(BLOCK,PORT,TYPE) requires a block and the number of one of its output ports.');
    end
    if nargin < 3 || isempty(type)
        type = 'input';
    end
    if nargin < 4 || isempty(ouverture)
        ouverture = 'off';
    end
    if nargin >= 5 && ~isempty(element)
        error('Simulink:Linearize:LinioBusElement', ...
              ['LINIO cannot refer to a bus element: the point holds the whole ' ...
               'signal of the port. A Bus Selector isolates the element, and the point goes ' ...
               'on its output.']);
    end
    if isnumeric(bloc) && isscalar(bloc) && ~isempty(matlibre_sl_signaux('cle', double(bloc)))
        bloc = getfullname(bloc);
    end
    if ~((ischar(bloc) && isrow(bloc)) || (isstring(bloc) && isscalar(bloc)))
        error('Simulink:Linearize:LinioBlock', ...
              ['LINIO(BLOCK,PORT,TYPE): BLOCK must be a block path, ''model/block'', ' ...
               'or its handle.']);
    end
    if ~(isnumeric(port) && isscalar(port) && isreal(port) && port >= 1 && port == fix(port))
        error('Simulink:Linearize:LinioPort', ...
              'LINIO(BLOCK,PORT,TYPE): PORT must be an output port number, a positive integer.');
    end
    [type, ouverture] = matlibre_sl_pointanalyse('canon', type, ouverture);
    io = struct('Active', 'on', 'Block', char(bloc), 'OpenLoop', ouverture, ...
                'PortNumber', double(port), 'Type', type, 'BusElement', '', ...
                'Description', '');
end
