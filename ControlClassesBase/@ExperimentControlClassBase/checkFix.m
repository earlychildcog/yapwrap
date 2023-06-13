function [roiFixated, timeFixated] = checkFix(xp, whichrect, padding, keyboardDummy, verbose)
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
    idScreenRect = find(any(screenRect));
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
timeFixated = NaN;

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

if keyboardDummy
    [keyIsDown, timeFixated_ ,keyCode] = PsychHID('KbCheck', xp.keyboard.index);      %reads key pressed
    if isnan(timeFixated)
        timeFixated = timeFixated_;
    end
    if keyIsDown
        switch find(keyCode,1)

            % This is for Fam Match and Test trials (3 AOIs)
            case KbName('leftarrow')
                roiFixated = 1;
                xp.eyelink.write('Pressed left key',timeFixated_)
                xp.eeg.eventSaveMultiIntoOne('klef', timeFixated_)
            case KbName('rightarrow')
                if length(whichrect) > 1
                    roiFixated = 2;
                    xp.eyelink.write('Pressed right key',timeFixated_)
                    xp.eeg.eventSaveMultiIntoOne('krig', timeFixated_)
                end
            case KbName('uparrow')
                if length(whichrect) > 2
                    roiFixated = 3;
                    xp.eyelink.write('Pressed up key',timeFixated_)
                    xp.eeg.eventSaveMultiIntoOne('keup', timeFixated_)
                end

                % This is for Fam Flip trials (9 AOIs)
            case KbName('1!')
                if length(whichrect) > 4 && find(keyCode,1,'last') == KbName('LeftShift')
                    roiFixated = 1;
                    xp.eyelink.write('Pressed key 1',timeFixated_)
                    xp.eeg.eventSaveMultiIntoOne('key1', timeFixated_)
                end
            case KbName('2@')
                if length(whichrect) > 4 && find(keyCode,1,'last') == KbName('LeftShift')
                    roiFixated = 2;
                    xp.eyelink.write('Pressed key 2',timeFixated_)
                    xp.eeg.eventSaveMultiIntoOne('key2', timeFixated_)
                end
            case KbName('3#')
                if length(whichrect) > 4 && find(keyCode,1,'last') == KbName('LeftShift')
                    roiFixated = 3;
                    xp.eyelink.write('Pressed key 3',timeFixated_)
                    xp.eeg.eventSaveMultiIntoOne('key3', timeFixated_)
                end
            case KbName('4$')
                if length(whichrect) > 4 && find(keyCode,1,'last') == KbName('LeftShift')
                    roiFixated = 4;
                    xp.eyelink.write('Pressed key 4',timeFixated_)
                    xp.eeg.eventSaveMultiIntoOne('key4', timeFixated_)
                end
            case KbName('5%')
                if length(whichrect) > 4 && find(keyCode,1,'last') == KbName('LeftShift')
                    roiFixated = 5;
                    xp.eyelink.write('Pressed key 5',timeFixated_)
                    xp.eeg.eventSaveMultiIntoOne('key5', timeFixated_)
                end
            case KbName('6^') && find(keyCode,1,'last') == KbName('LeftShift')
                if length(whichrect) > 4
                    roiFixated = 6;
                    xp.eyelink.write('Pressed key 6',timeFixated_)
                    xp.eeg.eventSaveMultiIntoOne('key6', timeFixated_)
                end
            case KbName('7&') && find(keyCode,1,'last') == KbName('LeftShift')
                if length(whichrect) > 4
                    roiFixated = 7;
                    xp.eyelink.write('Pressed key 7',timeFixated_)
                    xp.eeg.eventSaveMultiIntoOne('key7', timeFixated_)
                end
            case KbName('8*') && find(keyCode,1,'last') == KbName('LeftShift')
                if length(whichrect) > 4
                    roiFixated = 8;
                    xp.eyelink.write('Pressed key 8',timeFixated_)
                    xp.eeg.eventSaveMultiIntoOne('key8', timeFixated_)
                end
            case KbName('9(') && find(keyCode,1,'last') == KbName('LeftShift')
                if length(whichrect) > 4
                    roiFixated = 9;
                    xp.eyelink.write('Pressed key 9',timeFixated_)
                    xp.eeg.eventSaveMultiIntoOne('key9', timeFixated_)
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

