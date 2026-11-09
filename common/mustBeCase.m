function mustBeCase(c)
%MUSTBECASE Validate that c is a case struct returned by loadCase.
%   Use in an arguments block:  c (1,1) struct {mustBeCase}
%   Checks that the fields loadCase creates are present and have the expected
%   types, so a wrong input fails early with a clear message.

required = ["id", "img", "labels", "bladder", "info", "spacing"];
missing = required(~isfield(c, required));
if ~isempty(missing)
    error('mustBeCase:fields', 'Case struct is missing field(s): %s. Load it with loadCase.', ...
        strjoin(missing, ', '));
end

if ~(isstring(c.id) && isscalar(c.id))
    error('mustBeCase:id', 'c.id must be a string scalar, e.g. "002016".');
end
if ~(isa(c.img, 'double') && ndims(c.img) == 3)
    error('mustBeCase:img', 'Case %s: c.img must be a 3-D double volume.', c.id);
end
if ~isstruct(c.info)
    error('mustBeCase:info', 'Case %s: c.info must be the niftiinfo struct.', c.id);
end
if ~(isnumeric(c.spacing) && numel(c.spacing) == 3)
    error('mustBeCase:spacing', 'Case %s: c.spacing must be [dx dy dz] in mm.', c.id);
end
if ~isempty(c.labels) && ~isequal(size(c.labels), size(c.img))
    error('mustBeCase:labels', 'Case %s: c.labels must be empty or the same size as c.img.', c.id);
end
if ~isempty(c.bladder) && ~(islogical(c.bladder) && isequal(size(c.bladder), size(c.img)))
    error('mustBeCase:bladder', 'Case %s: c.bladder must be empty or a logical array the same size as c.img.', c.id);
end
end
