function [flagResult, timeTrigger] = playPretrial(xp)

%%
iFixX = randsample(1:10,1); % randomly pick which fix X sound to play

xp.settings.nStimOnScreen = 1;

rotationSpeed = 0;      % how fast it should rotate; 0 for no rotation
key = xp.keyboard.key;
flagLoop = true;
durframe = 0.1;
newangle = 0;
rect = xp.screen.rect(:,end-1);
texture = xp.image.texture{2,1};
Screen('DrawTexture', xp.screen.win, xp.image.texture{1,1}, [], xp.screen.rect(:,1));
Screen('DrawTexture', xp.screen.win, texture, [], rect,newangle);
timeStim = xp.flip;
flagResult = 0;
timeTrigger0 = GetSecs;
timeTrigger1 = timeTrigger0;
timeTriggerSound = timeTrigger0;
durMaxIn  = 0.5;
durMinOut = 0.05;
xp.eyelink.write('attget start @%.3fsec', timeStim)
while flagLoop
%     if newangle == 0
%         xp.sound.which = xp.sound.data{2,1};
%         xp.sound.play;
%     end

    if GetSecs - timeStim > durframe
        Screen('DrawTexture', xp.screen.win, xp.image.texture{1,1}, [], xp.screen.rect(:,1));
        Screen('DrawTexture', xp.screen.win, texture, [], rect,newangle);
        timeStim = xp.flip;
        newangle = mod(newangle - rotationSpeed,360);
    end
        % Play a sound every 3s
    if GetSecs-timeTriggerSound > 3 || timeTriggerSound == timeTrigger0
        xp.sound.stop;
        xp.sound.which = xp.sound.data{end,end+1-iFixX};
        xp.sound.play;
        timeTriggerSound = GetSecs; %reinitialise
    end
    [flagTrigger, timeTrigger] = xp.checkFix(-1, 1/15);           % do we need padding? change 0 to sth
%     fprintf('roi %d at %.3f\n', flagTrigger, timeTrigger - timeTrigger0);
    %%% keyboard check

    flagResult = xp.checkKeyboard(1);
    if flagResult
        flagLoop = false;
        if flagResult == 1
            timeTrigger = GetSecs;
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









