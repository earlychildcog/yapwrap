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
% NOTE: THE SCREEN ROI SHOULD BE LAST (IF INCLUDED)

persistent timeOutOfScreenStart
persistent roiOld
% this allows us to use 0 or negative numbers in the whichrect variable to index rects from the end of the xp.screen.rect matrix
whichrect(whichrect <= 0) = size(xp.screen.rect,2) + whichrect(whichrect <= 0);
if nargin < 5
    verbose = xp.debug > 0;
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
% if verbose
%     Screen('FillRect',xp.screen.win, 0, [0; 0; 1280; 1024]);
%     Screen('FillRect',xp.screen.win, 1, rectPadded(:,whichrect~=1));
% end
% timeFixated = NaN;


% which eye to use
if xp.eyetracker.status == 1
    pause(0.0001)
    gaze = xp.eyetracker.last_sample;
    x = gaze.x;
    y = gaze.y;
    eye_used = gaze.eye_used;
    timeFixated = gaze.time;
    roiFixated = zeros(size(eye_used));
    if eye_used(1) ~= -1 % do we know which eye to use yet?
        for iEye = 1:length(eye_used)
            % if we do, get current gaze position from sample
            if verbose
                fprintf('[%.4f gaze] eye %d:%f %f %.4f\n', GetSecs, eye_used(iEye), x(iEye), y(iEye), timeFixated);
            end
            % do we have valid data and is the pupil visible?
            if x(iEye)~=xp.eyetracker.MISSING_DATA && y(iEye)~=xp.eyetracker.MISSING_DATA % && evt.pa(eye_used(iEye)+1)>0
                % check if we hit any ROI
                for iROI = 1:nROI
                    if (y(iEye) > rectPadded(2,iROI)) && (y(iEye) < rectPadded(4,iROI))
                        if (x(iEye) < rectPadded(3,iROI)) && (x(iEye) > rectPadded(1,iROI))
                            roiFixated(iEye) = iROI;
                            break
                        end
                    end
                end
            end
        end
    end
else
    roiFixated  = 0;
    timeFixated = GetSecs;
end

% if we track both eyes...
if length(roiFixated) > 1
    if roiFixated(1) == roiFixated(2)
        roiFixated = roiFixated(1);
    else    % rois disagree
        if any(roiFixated == 0) % if one is out of any roi, we pick the other
            roiFixated = roiFixated(roiFixated ~= 0);
            % fprintf('gaze unstable: eye not detected, picking eye %d\n', find(roiFixated == 0));
        elseif any(roiFixated == idScreenRect)  % if one is screen, we pick the other valid roi
            roiFixated = roiFixated(roiFixated ~= idScreenRect);
            % fprintf('gaze unstable: eye somewhere on screen, picking eye %d\n', find(roiFixated ~= idScreenRect));
        elseif ~isempty(roiOld) && any(roiFixated == roiOld)    % if one is stable, we choose that and throw a warning
            roiFixated = roiFixated(roiFixated == roiOld);
            % fprintf('gaze unstable: different rois, picking old eye %d\n', find(roiFixated == roiOld));
        else        % wtf situation 2 rois chosen
            iEye = randi(2);
            roiFixated = roiFixated(iEye);
            fprintf(2,'gaze unstable, picking at random eye %d (%d roi)\n', iEye, roiFixated)
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
                xp.eyetracker.write(sprintf('Pressed key %d', keyroi),timeFixated_)
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
                xp.eyetracker.write(sprintf('Pressed key %s', roiAll{keyroi}),timeFixated_)
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
if roiFixated == 0 && xp.eyetracker.status == 1                   % AOI 0 = no gaze on screen
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

if roiFixated ~= 0
    roiOld = roiFixated;
else
    roiOld = [];
end
