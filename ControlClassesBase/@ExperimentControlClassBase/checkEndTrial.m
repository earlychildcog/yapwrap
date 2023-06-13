function trialResult = checkEndTrial(xp, trialResult, roiFix)
persistent timeTrialStart
% if already trial aborts
if nargin>1 && trialResult < 0
    return
end
% trial ends by looking away too long
if nargin>2 && roiFix == -6
    trialResult = -6;
    return
end
if isempty(timeTrialStart)
    timeTrialStart = GetSecs;
end

if GetSecs-timeTrialStart>xp.settings.durMaxTrial
    trialResult = -5;
end