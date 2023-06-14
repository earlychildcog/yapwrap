function [roiFixated, timeFixated, keyFlip] = checkFix(xp, whichrect, padding, keyboardDummy, verbose)
% function that checks if there is fixation in any of the rectangles
% we have defined, indicated in $whichrect. If yes, returns which rectangle
% in the above order. If keyboardDummy is true, A and D can be used for
% 1 and 2 ROI fixation return.
% NOTES:
% We need to check timings. Also, currently all ROIs are supposed to have
% the same y-coordinates (heights wrt screen). If different y-coordinates of boxes
% required, we need to adjust.
% Also, we need to time the "EyeAvailable" thing, in case it take too much
% time we should remove and adjust.

persistent timeOutOfScreenStart
whichrect(whichrect <= 0) = size(xp.screen.rect,2) + whichrect(whichrect <= 0);
if nargin < 5
    verbose = false;
    if nargin < 4
        keyboardDummy = true;
        if nargin < 3
            padding = 0;
        end
    end
end
keyFlip = false;
nROI = length(whichrect);
% TO DELETE FOR TESTING
% xp.screen.width  = 1280;
% xp.screen.height = 1024;

% Don't padd when many AOIs are tracked at once
if nROI>=9
    padding =0;
end

% Calculate padding
paddingPix = ceil(padding * xp.screen.height);

% Calculate new rect
rectPadded = xp.screen.rect(:,whichrect) + [-1 -1 1 1]'*paddingPix;
% If we are tracking a rect that represents the whole screen: set it back
% to the screen dimensions(don't padd it)
screenRect = all(rectPadded < [0; 0; Inf; Inf] & rectPadded > [-Inf; -Inf; xp.screen.width; xp.screen.height]);
if any(screenRect)
    rectPadded(:,screenRect) = [0; 0; xp.screen.width; xp.screen.height];
    idScreenRect = find(screenRect,1);          % we assume there is only one rect that ids as screen
else
    rectPadded = [rectPadded, [0; 0; xp.screen.width; xp.screen.height]];
    nROI = nROI + 1;   
    idScreenRect = nROI;
end

% ONLY FOR DEBUGGING --- DRAW NEW RECT TO SCREEN
% Note: make sure the background is not drawn in the DrawAllCards function
% as well
if verbose
    Screen('FillRect',xp.screen.win, 0, [0; 0; 1280; 1024]);
    Screen('FillRect',xp.screen.win, 1, rectPadded(:,whichrect~=1));
end
roiFixated  = 0;
% timeFixated = NaN;
timeFixated = GetSecs;

% which eye to use

if xp.eyelink.status == 1
    while Eyelink('NewFloatSampleAvailable') == 0 % waiting for sample...
    end

    eye_used = Eyelink('EyeAvailable');
    if eye_used == 2
        eye_used = 1;
    end
    % get the sample in the form of an event structure
    evt = Eyelink('NewestFloatSample');
    if eye_used ~= -1 % do we know which eye to use yet?
        % if we do, get current gaze position from sample
        x = evt.gx(eye_used+1); % +1 as we're accessing MATLAB array
        y = evt.gy(eye_used+1);
        timeFixated = GetSecs;
        if verbose
            fprintf('%f %f %.4f\n',x, y, GetSecs);
        end
        % do we have valid data and is the pupil visible?
        if x~=xp.eyelink.settings.MISSING_DATA && y~=xp.eyelink.settings.MISSING_DATA && evt.pa(eye_used+1)>0
            % check if we hit any ROI
            for iROI = 1:nROI
                if (y > rectPadded(2,iROI)) && (y < rectPadded(4,iROI))
                    if (x < rectPadded(3,iROI)) && (x > rectPadded(1,iROI))
                        roiFixated = iROI;
                        break
                    end
                end
            end
        end
    end
end

% manual controlled through keyboard
if keyboardDummy
    [keyIsDown, timeFixated_ ,keyCode] = PsychHID('KbCheck', xp.keyboard.index);      %reads key pressed
    % if isnan(timeFixated)         % not sure why this is here, should remove if all works
    %     timeFixated = timeFixated_;
    % end
    if keyIsDown
        if keyCode(KbName('LeftShift'))
            roiAll = {'1!' '2@' '3#' '4$' '5%' '6^' '7&' '8*' '9('};
            if length(whichrect) < length(roiAll)
                roiAll = roiAll(1:length(whichrect));
            end
            keyroi = find(keyCode(KbName(roiAll)), 1);
            if ~isempty(keyroi)
                roiFixated = keyroi;
                xp.eyelink.write(sprintf('Pressed key %d', keyroi),timeFixated_)
                xp.eeg.eventSaveMultiIntoOne(sprintf('key%d', keyroi), timeFixated_)
                keyFlip = true;
                timeFixated = timeFixated_;
            end
        else
            roiAll = {'leftarrow' 'rightarrow' 'uparrow'};
            if length(whichrect) < length(roiAll)
                roiAll = roiAll(1:length(whichrect));
            end
            keyroi = find(keyCode(KbName(roiAll)), 1);
            if ~isempty(keyroi)
                roiFixated = keyroi;
                xp.eyelink.write(sprintf('Pressed key %s', roiAll{keyroi}),timeFixated_)
                xp.eeg.eventSaveMultiIntoOne(sprintf('key%s', roiAll{keyroi}), timeFixated_)
                keyFlip = true;
                timeFixated = timeFixated_;
            end
        end
    end
    if verbose
        fprintf('roi:%d @%.4fs\n', roiFixated, GetSecs)
    end
end
% looking away condition to end trial
if roiFixated == 0                    % AOI 0 = no gaze on screen
    if isempty(timeOutOfScreenStart)
        timeOutOfScreenStart = timeFixated;
    elseif timeFixated - timeOutOfScreenStart > xp.settings.durMaxLookAway
        roiFixated = -6;
    end
else
    timeOutOfScreenStart = [];  % reset look away time
    if roiFixated == idScreenRect % the last AOI is the screen (to check if baby is looking away) -- turn this into 0 for ease of use
        roiFixated = 0;
    end
end

