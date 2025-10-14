classdef GazeSampleClass
    % class for specifying the gaze sample structure
    % essentially makes sure that all implementations of EyetrackerControlClassBase abstract class implement this pattern
    % as appearing in eyetracker.last_sample property
    % It is not expected to contain any complicated methods except the constructor
    properties
        eye_used (1,:) int8  = 0            % 0 for left, 1 for right. Matters in stuff like projecting gaze on mirror screen. In principle, if only one eye is used, it does not matter which
        time (1,:) double    = GetSecs();   % in general, time should be expected to be in SECONDS and match the GETSECS psychtoolbox function
        x (1,:) double       = NaN          % x gaze coordinate IN SCREEN PIXELS
        y (1,:) double       = NaN          % y  »  »  »  »  »  IN SCREEN PIXELS
        nSample (1,1) uint64 = 0            % counter for the received samples
    end
    methods
        function gaze = GazeSampleClass(struct_)
            arguments
                struct_ struct = []
            end
            if ~isempty(struct_)
                gaze.eye_used = struct_.eye_used;
                gaze.time = struct_.time;
                gaze.x = struct_.x;
                gaze.y = struct_.y;
                gaze.nSample = gaze.nSample + 1;
            end
        end
    end
end
