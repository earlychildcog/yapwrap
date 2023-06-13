function [durFixIn, flagActive, timeFirstIn] = checkROI(xp, roiFix, timeFix)
% checks ROI fixation durations based on fixation data at each timepoint
% input:
%
% output:
%   durFixIn: how long it has been in the same ROI
%   durFixOut: in case of changing ROI, how long it has been away from previous ROI, until fixation to new ROI has been registered
% WE NEED TO IMPROVE: COMPUTE 2 ARRAYS, ONE SAVES TIMEFIX FOR LAST SECOND, THE OTHER THE ROIS FOR EACH TIMEFIX

% initialise local variables
persistent roiFixIn timeFixIn N roiActive
if isempty(roiFixIn)
    roiFixIn = zeros(1,1000);
    timeFixIn = [GetSecs, zeros(1, length(roiFixIn))];
    N = 1;
    roiActive = 0;
end

flagActive = roiActive == roiFix;

% Get how long fixation has been going and whether to switch to a new AOI
% if fixation is lost, then timer resets to new roi after $timeOut seconds
if roiFix == roiFixIn(N) % if look away then back to the same: add to the former count

    [durFixIn, timeFirstIn] = computeDurFix(roiFixIn(1:N), timeFixIn(1:N), roiFix, timeFix);
    if roiActive ~= roiFix && durFixIn >  xp.settings.timeOut
        xp.eyelink.write('roichange: from %d to %d @%.3fsec', roiActive, roiFix, timeFix)
        roiActive = roiFix;
    end
    
else % if looks to a roi different to last roi: make a new count
    N = N + 1;
    timeFixIn(N) = timeFix;
    roiFixIn(N) = roiFix;
    durFixIn = 0;
    timeFirstIn = timeFix;
end
end


function [durFixIn, timeFirstIn] = computeDurFix(roiFixIn, timeFixIn, roiFix, timeFix)
durs = diff([timeFixIn, timeFix]);
n = length(roiFixIn);
durFixIn = 0;
r = 0;
for k=n:-1:1
    if roiFixIn(k) ~= roiFix
        r = r + durs(k);
        if r > 0.2
            break
        end
    else
        index = k;
        durFixIn = durFixIn + durs(k);
        if durs(k) > 0.2
            r = 0;
        end
    end
end
timeFirstIn = timeFixIn(index);
end