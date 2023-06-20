classdef ExperimentControlClassBase < handle
    % Some description
    properties
        % experiment session settings
        name            = 'cur';
        subject         = [];
        session         = [];
        sessionNo       = [];
        group           = [];
        trialN          = [];
        blockN          = [];
        trialVars       = {};
        framedur        = 0.033;
        offset          = 0.011;
        condList        = {};
        prestype        = {};
        debug           = false;

        settings        = struct;

        config          = 'default_config'
        
%         log                 {mustBeA(log,'LogControlClass')}        % log settings
        screen              ScreenControlClassBase      = ScreenControlClassBase  % screen settings
        sound               SoundControlClassBase       = SoundControlClassBase   % sound settings
        keyboard            KeyControlClassBase         = KeyControlClassBase     % keyboard settings
        image               ImageControlClassBase       = ImageControlClassBase   % image settings

        trial               TrialControlClassBase       = TrialControlClassBase   % trial settings

        eyelink             EyelinkControlClassBase     = EyelinkControlClassBase % eyelink settings
        
        eeg                 EegControlClassBase         = EegControlClassBase      % EEG settings
        log                 LogControlClassBase         = LogControlClass
    end
    
    methods
        function xp = ExperimentControlClassBaseBase(status)
            
            xp.image    = ImageControlClassBase;
            xp.screen   = ScreenControlClassBase;
            xp.eyelink  = EyelinkControlClassBase;
            xp.eeg      = EegControlClassBase;
            xp.sound    = SoundControlClassBase;
            xp.keyboard = KeyControlClassBase;
            xp.trial    = TrialControlClassBase;
            xp.log      = LogControlClassBase;
            if nargin == 0 || ~status
                return
            else
                xp.init
            end
        end

        % prompt for experiment name
        function getExpName(xp)
            xp.name = 'curE';
        end

        % prompt for subject/session name
        function setSubjNo(xp)
            subjno = 0;
            sessionId = '';
            listSessions = {'a' 'b' 'c' 'p'};
            while subjno == 0
                while isempty(subjno) || subjno <= 0 || subjno > 499
                    subjno = round(input('\ngive subject number (1-499):'));
                end
                while isempty(sessionId) || ~ismember(sessionId, listSessions)
                    sessionId = input(['\ngive sessionid (' [listSessions{:}] '):'],'s');
                end
                edfname = sprintf('%s%.3d%c.edf', xp.name, subjno, sessionId);
                if exist(fullfile(xp.eyelink.edffolder, edfname),'file')>0
                    warning('edf file for subject number %d session %c already exists, please choose another number', subjno, sessionId)
                    subjno = 0;
                    sessionId = '';
                end
            end
            xp.subject = subjno;
            xp.session = sessionId;
            xp.sessionNo = find([listSessions{:}] == sessionId);
            if xp.sessionNo == 4
                xp.sessionNo = 1;
            end

            % careful: edf filename must be up to 8 letters (without the extension)
            xp.eyelink.edfname = edfname;
        end
        function init(xp)
            %get information for this session
            
            xp.keyboard.init;

            xp.image.screen = xp.screen;                        % link image control class to screen
            
            PsychDefaultSetup(2);                               % initiate psychtoolbox with default settings
            
            xp.keyboard.init;                                   % initialise keyboard
            rng('shuffle');     % shuffle the random generator for a random seed
            % adds a log folder in case there is not one;
            if exist('logs','file') ~= 7
                mkdir('logs')
            end
            if exist('logs/debug','file') ~= 7
                mkdir('logs/debug')
            end
            diary(sprintf('logs/debug/%s_%.3d.log',xp.name,xp.subject));     % a basic log of command line trash
            
            
            if ~xp.debug            % unless we operate in debug mode, we disable mouse cursor and keyboard input
                ListenChar(2);      % Disable keyboard input messing up in the command window/script
                HideCursor();       % Hiding mouse cursor
            end
            
            xp.screen.init;         % initialise screen --- we have preset configuration already
            Screen('BlendFunction', xp.screen.win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');   % enable transparency
            
            xp.sound.init;          % initialise sound

            fprintf('\n****************************************\nExperiment %s\n',xp.name);
            fprintf('%s\n',datestr(now));
            fprintf('Subject %s\n\n',xp.subject);
            
            xp.eyelink.screen = xp.screen;
            xp.eyelink.trial = xp.trial;
            xp.eyelink.calib_pahandle = xp.sound.pahandle;
            xp.log.trial = xp.trial;
        end

        %class destructor
        function delete(xp)
            % stuff
            xp.image.delete();
            xp.sound.delete();
            xp.trial.delete();
            xp.screen.delete();
            xp.eyelink.delete();
            xp.log.delete();
            xp.delete()
%             clear ExperimentControlClass
        end
        
        % function to load configuration settings file
        function loadconfig(xp)
            eval([xp.config '(xp)']);                   % HORRIBLE need to change that later
        end
        
        %% screen control functions
        
        % erases screen
        function time = erase(xp)
            xp.fill;
            time = xp.flip;
        end
        
        % buffers with a $colour rectangle for later use
        function fill(xp,colour)
            if ~exist('colour','var')
                colour = xp.screen.backcolour;
            elseif ischar(colour)
                colour = xp.screen.colour.(colour);
            end
            Screen('FillRect',xp.screen.win,colour);
        end

        % shows image from texture pointer
        function time = showIm(xp,txtpoint,time)
            if nargin < 3
                time = 0;
            end
            Screen('DrawTexture', xp.screen.win, txtpoint, [], xp.screen.full);
            time = xp.flip(time);
        end

        % draws image from texture pointer
        function drawIm(xp,txtpoint,rectID)
            if nargin < 3 || rectID == 0
                rect = xp.screen.full;
            else
                rect = xp.screen.rect(:,rectID);
            end
            Screen('DrawTexture', xp.screen.win, txtpoint, [], rect);
        end


        % draws image from multiple texture pointers at once
        function drawIms(xp,txtpoints,rectIDs)
            if ~exist('rectID','var') || rectIDs == 0
                rectIDs = 1:length(txtpoints);
            end
            rect = xp.screen.rect(:,rectIDs);
            Screen('DrawTextures', xp.screen.win, txtpoints, [], rect);
        end

        % displays texture in buffer
        function time = flip(xp,time,dontclear)
            if nargin < 2 || isempty(time)
                time = 0;
            end
            if nargin < 3 || isempty(dontclear)
                dontclear = 0;
            end
            time = Screen('Flip',xp.screen.win, time, dontclear);
        end
        
        
        %% experiment control functions
        function state = pause(xp)
            xp.suspend;
            fprintf('\nPress SPACE to resume or Q to Quit\n');
            if xp.waitSpace
                xp.finish;
                state = -1;
                return
            else
                xp.resume;
                state = 1;
                return
            end
        end
        
        
        function state = checkPause(xp)
            pauseKey = KbName('p');
            breakKey = KbName('b');
            quitKey = KbName('q');
            
            if xp.isKey(pauseKey)
                state = xp.pause;
                return
            end
            if xp.isKey(breakKey)
                state = 2;
                return
            end
            if xp.isKey(quitKey)
                state = -1;
                return
            end

            state = 0;
        end
        
        function state = checkKey(xp)
            keys = xp.keyboard.keyNums;
            if xp.isKey(pauseKey)
                state = xp.pause;
                return
            end
            [keyIsDown,~,keyCode] = KbCheck();      %reads key pressed 
            if keyIsDown && ismember(find(keyCode,1),keylist)
                key = find(keyCode,1);
                return
            end
            state = false;
        end

%         function suspend(xp)
%             if false
%                 NetStation('StopRecording')
%             end
%             xp.erase;
%         end
%         
%         function resume(xp)
%             if false
%                 NetStation('StartRecording');
%             end
%         end

        function state = waitSpace(xp)
            
            QKEY = KbName('q');
            SPACEKEY = KbName('space');
            while 1
                if isKey(xp,QKEY)
                    state = 1;
                    FlushEvents('keyDown');
                    while isKey(xp,QKEY)
                    end
                    return;
                 elseif isKey(xp,SPACEKEY)
                    state = 0;
                    return;
                end
            end
        end
        
        function state = isKey(xp,key)
            [ ~ , ~ , keyCode ] = KbCheck();
            if ~isnumeric(key)
                kc = KbName(key);
            else
                kc = key;
            end
            state = keyCode(kc);
        end
        
        function key = waitForKeys(xp,keylist)
            while 1
                [keyIsDown,~,keyCode] = KbCheck();      %reads key pressed 
                if keyIsDown && ismember(find(keyCode,1),keylist)
                    key = find(keyCode,1);
                    return
                end
            end
        end
        
        
        function state = waitToChoose(xp,keylist)
            key = xp.waitForKeys(keylist);
            state = find(key == keylist);
        end
        
        function finish(xp)
            
            ListenChar(0);          %reactivate keyboard
            ShowCursor();           %show cursor again
        
            
            if xp.eyelink.status
                xp.eyelink.cleanup;
            end
            
            WaitSecs(1);
            diary off;
            if xp.screen.win >=0
                xp.erase;
                Screen('CloseAll');
                xp.screen.win = -1;
                ShowCursor();
            end
            PsychPortAudio('Close');
        end

        function clear(xp)
            % be careful with this one!
            clear xp.trial
            clear xp
        end
        

    end
end