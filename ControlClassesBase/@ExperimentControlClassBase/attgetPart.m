function [flagResult, time] = attgetPart(xp, flagAnimate)
arguments
    xp
    flagAnimate logical = false % control if we show an animated or static pre-trial fixation grabber
end
flagResult = -10;
xp.eyelink.startrec;
while flagResult < 0
    % choose between an animated or static pre-trial fixation grabber
    if flagAnimate
        [flagResult, time] = playPretrialVideo(xp);
    else
        [flagResult, time] = playPretrial(xp);
    end
    if flagResult == -1     % recalibrate
        xp.trial.varValue.result = flagResult;
        xp.eyelink.stoprec;
        xp.eyelink.calibrate;
        xp.eyelink.startrec;
    elseif flagResult < -20 % play video
        xp.trial.varValue.result = flagResult;
        xp.eyelink.stoprec;
        idBreak = -flagResult-20;
        xp.sound.which = xp.sound.data{3,idBreak};
        xp.videoPlay(xp.trial.videoList(idBreak), 1, 1);
        xp.eyelink.startrec;
    elseif flagResult == -3 % skip trial; get a small break first, though
        xp.trial.varValue.result = flagResult;
        xp.eyelink.stoprec;
        xp.erase
        WaitSecs(0.1);
        break
    elseif flagResult == -9
        xp.trial.varValue.result = flagResult;
        xp.eyelink.stoprec;
        xp.erase
        WaitSecs(0.1);
        break
    end
end
end