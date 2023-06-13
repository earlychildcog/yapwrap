function [flagResult, timeTrigger] = playPretrial(xp)

%%
xp.settings.nStimOnScreen = 1;
rotationSpeed = 0;      % how fast it should rotate; 0 for no rotation
key = xp.keyboard.key;
flagLoop = true;
durframe = 0.1;
newangle = 0;
rect = xp.screen.rect(:,end-1);
texture = xp.image.texture{2,1};
Screen('DrawTexture', xp.screen.win, texture, [], rect,newangle);
timeStim = xp.flip;
flagResult = 0;
timeTrigger0 = GetSecs;
timeTrigger1 = GetSecs;
durMaxIn = 1;
durMinOut = 0.05;
xp.eyelink.write('attget start @%.3fsec', timeStim)
while flagLoop
    if GetSecs - timeStim > durframe
        Screen('DrawTexture', xp.screen.win, texture, [], rect,newangle);
        timeStim = xp.flip;
        newangle = mod(newangle - rotationSpeed,360);
    end
    
    [flagTrigger, timeTrigger] = xp.checkFix(-1, 1/15);
    %%% keyboard check
    [keyIsDown,~,keyCode] = PsychHID('KbCheck', xp.keyboard.index);      %reads key pressed
    if keyIsDown
        switch find(keyCode,1)
            case key.escape
                flagLoop = false;
                flagResult = -3;
            case key.q
                flagLoop = false;
                flagResult = -9;
            case key.space
                flagLoop = false;
                flagResult = 1;
                timeTrigger = GetSecs;
            case key.c
                flagLoop = false;
                flagResult = -1;         % calibrate
            case key.s
                xp.sound.which = xp.sound.data{1,randi(6)};
                xp.sound.play;
                WaitSecs(0.1)
            case key.p
                flagLoop = false;
                flagResult = -2;
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
