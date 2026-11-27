function poignees = findBlocks(systeme, varargin)
%SIMULINK.FINDBLOCKS Les blocs d'un système, par leurs poignées.
%   H = SIMULINK.FINDBLOCKS(SYSTEME) rend en colonne les poignées de tous
%   les blocs du système — un modèle de la session ou un de ses
%   sous-systèmes, désigné par son nom, son chemin ou sa poignée —, à
%   tous les niveaux et sous les masques.
%   H = SIMULINK.FINDBLOCKS(SYSTEME,'Param',VALEUR,...) ne garde que ceux
%   dont les paramètres ont ces valeurs.
%   H = SIMULINK.FINDBLOCKS(...,OPTIONS) cherche comme le dit le
%   Simulink.FindOptions donné en dernier ; son MatchFilter, une fonction
%   qui reçoit la poignée de chaque bloc trouvé, ne garde que ceux pour
%   lesquels elle rend vrai.
%
%   GETFULLNAME(H) rend leurs chemins, GET_PARAM(H,...) les lit.
%
%   Exemple :
%      bdclose('all');
%      new_system('essai');
%      add_block('built-in/Gain', 'essai/g1', 'Gain', '2');
%      add_block('built-in/Gain', 'essai/g2', 'Gain', '3');
%      add_block('built-in/Constant', 'essai/c');
%      numel(Simulink.findBlocks('essai'))                   % 3
%      getfullname(Simulink.findBlocks('essai', 'Gain', '3'))  % 'essai/g2'
%      bdclose('all');
%
%   Voir aussi SIMULINK.FINDBLOCKSOFTYPE, SIMULINK.FINDOPTIONS, FIND_SYSTEM.
    if isstruct(systeme)
        error('Simulink:Commands:FindBlocksNeedsLoadedModel', ...
              ['Simulink.findBlocks returns handles, which only models loaded in the ' ...
               'session have: give the model by its name. FIND_SYSTEM(MODEL,...) searches ' ...
               'a model passed by value.']);
    end
    options = Simulink.FindOptions;
    if ~isempty(varargin) && isa(varargin{end}, 'Simulink.FindOptions')
        options = varargin{end};
        varargin(end) = [];
    end
    if mod(numel(varargin), 2) ~= 0
        error('Simulink:Commands:FindBlocksPairs', ...
              'Simulink.findBlocks(SYSTEM,NAME,VALUE,...): criteria must be name-value pairs.');
    end
    arguments = options.enArguments();
    ici = getfullname(get_param(systeme, 'Handle'));
    poignees = find_system(ici, arguments{:}, 'FindAll', 'on', 'Type', 'block', varargin{:});
    % le système lui-même n'est pas l'un de ses blocs
    poignees = poignees(poignees ~= get_param(systeme, 'Handle'));
    % MatchFilter garde les blocs pour lesquels il rend vrai
    if ~isempty(options.MatchFilter)
        garde = false(size(poignees));
        for k = 1:numel(poignees)
            garde(k) = logical(options.MatchFilter(poignees(k)));
        end
        poignees = poignees(garde);
    end
end
