function varargout = pararrayfun(fonction, varargin)
%PARARRAYFUN Équivalent parallèle d'ARRAYFUN (exécution séquentielle).
    [varargout{1:max(nargout,1)}] = arrayfun(fonction, varargin{:});
end
