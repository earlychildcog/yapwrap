function [flagResult, keyOnset]= checkKeyboard(xp, attget)
arguments
    xp
    attget = false
end
% reads the keyboard for each loop during a trial
% negative $flagResult values end the trial

persistent timeLastSound timeLastEscape        % variable that saves the last time a sound key has been played
key = xp.keyboard.key;
[keyIsDown,keyOnset,keyCode] = KbCheck();      %reads key pressed
flagResult = 0;
if keyIsDown
    keys = find(keyCode);

    % skip trial
    if any(keys == key.escape)
        if isempty(timeLastEscape) || GetSecs - timeLastEscape > 0.5
            timeLastEscape = keyOnset;
            flagResult   = -3;
            xp.eyelink.write('Pressed escape key - skip trial @%.3fsec',keyOnset)
            xp.eeg.eventSave('kesc', keyOnset)
        end

    % quit
    elseif any(keys ==  key.q)
        flagResult   = -9;
        xp.eyelink.write('Pressed q key - quit experiment @%.3fsec',keyOnset)
        xp.eeg.eventSave('kqui', keyOnset)

    % calibrate
    elseif any(keys ==  key.c)
        flagResult   = -1;        
        xp.eyelink.write('Pressed c key - recalibrate @%.3fsec',keyOnset)
        xp.eeg.eventSave('kcal', keyOnset)

    % gogogo to trial
    elseif any(keys ==  key.space) && attget
        flagResult   = 1;         
        xp.eyelink.write('Pressed space key - go to trial @%.3fsec',keyOnset)
        xp.eeg.eventSave('kspc', keyOnset)

    % plays attention sound
    elseif any(keys ==  key.s)                      
        if isempty(timeLastSound) || GetSecs - timeLastSound > 0.5       % making sure it is not just key staying pressed
            xp.sound.which = xp.sound.data{1,randi(6)};
            timeLastSound  = xp.sound.play;
            xp.eyelink.write('Pressed s key - play sound random attention sound @%.3fsec',keyOnset)
            xp.eeg.eventSave('ksou', timeLastSound)
        end

    % play break video
    elseif ~any(keys ==  KbName('LeftShift')) && any(keys ==  KbName({'1!' '2@' '3#' '4$' '5%'})', 'all')
        idBreakvideo = find(any(keys ==  KbName({'1!' '2@' '3#' '4$' '5%'})', 2),1);
        flagResult   = -20 - idBreakvideo;
        xp.eyelink.write('Pressed %d key - play pause video @%.3fsec',idBreakvideo, idBreakvideo, keyOnset)
        xp.eeg.eventSave('kpau', keyOnset)
    end
end
end