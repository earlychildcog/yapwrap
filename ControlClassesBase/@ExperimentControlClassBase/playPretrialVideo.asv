function [flagResult, timeTrigger] = playPretrialVideo(xp)

%%
iFixX = randsample(1:10,1); % randomly pick which fix X to play

xp.settings.nStimOnScreen = 1;
rotationSpeed = 0;      % how fast it should rotate; 0 for no rotation; e.g. 10 to rotate
key = xp.keyboard.key;
flagLoop = true;
durframe = 0.1;
newangle = 0;
rect = xp.screen.rect(:,end);
iFrame  = 1;
texture = xp.image.texture{end+1-iFixX,iFrame};
Screen('DrawTexture', xp.screen.win, xp.image.texture{1,1}, [], xp.screen.rect(:,1));
Screen('DrawTexture', xp.screen.win, texture, [], rect,newangle);
timeStim = xp.flip;
flagResult = 0;
timeTrigger0 = GetSecs;
timeTrigger1 = GetSecs;
durMaxIn = 1;
durMinOut = 0.05;
xp.eyelink.write('attention getter (fix x) start @%.3fsec', timeStim)
xp.sound.which = xp.sound.data{end,end+1-iFixX}; %whoop in

while flagLoop

    % Play sound only first the first frame
     if iFrame == 1
        xp.sound.stop;
        xp.sound.play(0,0);
    end

    if GetSecs - timeStim > durframe - 0.003
        iFrame  = iFrame + 1;
        if iFrame > sum(~cellfun(@isempty,xp.image.texture(end+1-iFixX,:)))
            iFrame = 1;
        end
        texture = xp.image.texture{end+1-iFixX,iFrame};
        Screen('DrawTexture', xp.screen.win, xp.image.texture{1,1}, [], xp.screen.rect(:,1));
        Screen('DrawTexture', xp.screen.win, texture, [], rect,newangle);
        timeStim = xp.flip(timeStim + durframe);
        newangle = mod(newangle - rotationSpeed,360);
    end
    
    [flagTrigger, timeTrigger] = xp.checkFix(-1, 1/15);
    %%% keyboard check
    [flagResult, keyOnset] = checkKeyboard(xp, 1);
    if flagResult ~= 0
        flagLoop = false;
        if flagResult == 1
            timeTrigger = keyOnset;
        end
    end

    if flagTrigger == 0 && timeTrigger-timeTrigger1>durMinOut
        timeTrigger0 = timeTrigger;
    elseif flagTrigger == 1 
        if timeTrigger-timeTrigger0>durMaxIn    
            flagLoop = false;
            flagResult = 1;
        else
            timeTrigger1 = timeTrigger;
        end
    end

end
xp.sound.stop;
xp.eyelink.write('attget stop with %d @%.3fsec', flagResult, timeStim)
