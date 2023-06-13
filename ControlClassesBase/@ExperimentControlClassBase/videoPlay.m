function flagResult = videoPlay(xp, pathVideofile, rectID, volume, loop)

if nargin < 3 || isempty(rectID)
    rectID = 0;
end
if nargin < 4 || isempty(volume)
    volume = xp.sound.volume;
end
if nargin < 5 || isempty(loop)
    loop = true;
end
if volume>0
    volume_old = xp.sound.volume;
    xp.sound.volume = volume;
end
framedur = xp.framedur;
offset = xp.offset;
% newrect = round([(RECT(3:4)+RECT(1:2))/2-(RECT(3:4)-RECT(1:2))/8 (RECT(3:4)+RECT(1:2))/2+(RECT(3:4)+RECT(1:2))/8]);
% disp(newrect)
% disp(RECT)

%[mov, ~, ~, Movx, Movy] = Screen('OpenMovie', EXPWIN, movfile,4,-1,1,6);
[mov, ~, ~, Movx, Movy] = Screen('OpenMovie', xp.screen.win, char(pathVideofile),4,-1,1+2,6);

Qkey        = KbName('q');
Pkey        = KbName('p');
Ckey        = KbName('c');
Bkey        = KbName('b');
SPACE       = KbName('space');

Screen('SetMovieTimeIndex', mov, 0);
Screen('PlayMovie', mov, 1,0,0);
frameNum = 0;
% PsychPortAudio('FillBuffer', pahandle, wav)
% PsychPortAudio('Volume',pahandle,0.8)
% PsychPortAudio('Start', pahandle);

if volume>0
    xp.sound.play;
end

thisframe = 0;
StimulusOnsetTime = GetSecs();
while 1
    [thisframe] = Screen('GetMovieImage', xp.screen.win, mov, 1, [], [], 1);
    if thisframe== -1
        if loop
            Screen('SetMovieTimeIndex', mov, 0);
            %Screen('PlayMovie', mov, 1,0,0);
            [thisframe] = Screen('GetMovieImage', xp.screen.win, mov, 1, [], [], 1);
    %         PsychPortAudio('Stop', xp.sound.pahandle,0);
            if volume>0
                xp.sound.stop;
                xp.sound.play;
            end
            frameNum = 0;
        else
            break
        end
    end
    
    frameNum = frameNum + 1;
%     Screen('DrawTexture', EXPWIN, thisframe, [], newrect);
    xp.drawIm(thisframe,rectID)
    StimulusOnsetTime = xp.flip(StimulusOnsetTime + framedur - offset);
%     Screen('FillRect',EXPWIN,BACKCOLOR);
%     StimulusOnsetTime = Screen('Flip', EXPWIN, StimulusOnsetTime + framedur - offset);
%     disp(frameNum)
    %conditions for presentation to stop
%     if thisframe== -1     % Valid texture returned? A negative value means end of movie reached: 
%         mov = mov0;
%         [thisframe] = Screen('GetMovieImage', EXPWIN, mov, 1, [], [], 1);
% %                 PsychPortAudio('FillBuffer', pahandle, musicbreak');
%         %PsychPortAudio('Stop', pahandle,0);
%     end
    
    [keyIsDown,~,keyCode] = KbCheck();      %reads key pressed 
        
    if keyIsDown && frameNum > 3        % making sure a button is not just pressed before

        switch find(keyCode,1)

% skip video when SPACE key is pressed
            case SPACE
                flagResult = 1;
                break

%Press C to calibrate again during break

            case Ckey
                flagResult = -1;
                break

% stop experiment when Q key is pressed
            case Qkey
                flagResult = -9;
                return
        end
    end
    Screen('Close', thisframe);
end
% PsychPortAudio('Stop', pahandle,0);
Screen('PlayMovie', mov, 0);            % Done. Stop playback:
Screen('CloseMovie',mov);               % Close movie object:    
if volume>0
    xp.sound.stop;
    xp.sound.volume = volume_old;
end
WaitSecs(0.1);









