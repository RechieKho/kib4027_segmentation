classdef BladderCase
%BLADDERCASE One test case: T2 MRI volume, reference masks and header.
%   c = BladderCase(cfg, caseId) loads <caseId>_img.nii and, if present,
%   <caseId>_mask.nii from cfg.dataDir. loadCase(cfg, caseId) does the same.
%
%   Arrays stay in the file's native voxel order so predicted masks line up
%   with the reference masks voxel for voxel. Use toDisplayOrientation only
%   for figures.
%
%   Properties are read-only. To change an array, copy it first, e.g.
%   I = c.img; I = imgaussfilt3(I, 1);
%
%   In a function, declare the argument as  c (1,1) BladderCase  so MATLAB
%   checks the input and the editor suggests the properties below.
%   c.checkPrediction(bw) checks a method's output mask against this case.

    properties (SetAccess = immutable)
        % Case id, e.g. "002016"
        id (1,1) string = ""

        % T2-weighted volume as double (the files store int16, uint16,
        % single or double, so every case is converted)
        img (:,:,:) double

        % Voxel size in mm, [dx dy dz] along the array dimensions
        spacing (1,3) double = [1 1 1]

        % niftiinfo of the image. savePredictedMask uses it as the header.
        info (1,1) struct

        % GROUND TRUTH: multi-class reference mask (labels 0-8), same size as
        % img, or empty if the case has no mask. Do not use in a method.
        labels (:,:,:) uint8

        % GROUND TRUTH: bladder mask (labels == cfg.bladderLabel), same size
        % as img, or empty if the case has no mask. Do not use in a method.
        bladder (:,:,:) logical
    end

    methods
        function c = BladderCase(cfg, caseId)
            arguments
                cfg (1,1) struct
                caseId (1,1) string
            end
            imgFile  = fullfile(cfg.dataDir, caseId + "_img.nii");
            maskFile = fullfile(cfg.dataDir, caseId + "_mask.nii");

            c.id = caseId;
            c.info = niftiinfo(imgFile);
            c.img = double(niftiread(c.info));
            c.spacing = double(c.info.PixelDimensions(1:3));

            if isfile(maskFile)
                labels = niftiread(maskFile);
                if ~isequal(size(labels), size(c.img))
                    error('BladderCase:sizeMismatch', 'Case %s: image %s and mask %s differ in size.', ...
                        caseId, mat2str(size(c.img)), mat2str(size(labels)));
                end
                c.labels = uint8(round(labels));     % some masks are stored as single
                c.bladder = c.labels == cfg.bladderLabel;
            end
        end

        function checkPrediction(c, bw)
            %CHECKPREDICTION Error unless bw is a valid predicted mask for this case.
            %   c.checkPrediction(bw) checks the agreed method output: a logical
            %   array the same size as c.img (native voxel order, true = bladder).
            %   Warns if the mask is empty, which usually means the method failed.
            if ~islogical(bw)
                error('BladderCase:predictionType', 'Case %s: predicted mask must be logical, not %s.', ...
                    c.id, class(bw));
            end
            if ~isequal(size(bw), size(c.img))
                error('BladderCase:predictionSize', ...
                    'Case %s: predicted mask is %s but c.img is %s. Resample back to the original grid.', ...
                    c.id, mat2str(size(bw)), mat2str(size(c.img)));
            end
            if ~any(bw, 'all')
                warning('BladderCase:emptyPrediction', 'Case %s: predicted mask is empty.', c.id);
            end
        end
    end
end
