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
        eyetracker             % eyelink or pupillo?
        eeg                 EegControlClassBase         = EegControlClassBase      % EEG settings
        log                 LogControlClassBase         = LogControlClass
    end
    methods
        function xp = ExperimentControlClassBaseBase(status)

            xp.image    = ImageControlClassBase;
            xp.screen   = ScreenControlClassBase;
            xp.eyetracker = PupilloControlClassBase;
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
                if exist(fullfile(xp.eyetracker.edffolder, edfname),'file')>0
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
            xp.eyetracker.savefile = edfname;
        end
        function init(xp)
            %get information for this session

            xp.keyboard.init;

            xp.image.screen = xp.screen;                        % link image control class to screen

            PsychDefaultSetup(2);                               % initiate psychtoolbox with default settings

            xp.keyboard.init;                                   % initialise keyboard
            rng('shuffle');     % shuffle the random generator for a random seed
            % adds a log folder in case there is not one;
            if ~isfolder('logs/debug')
                mkdir('logs/debug')
            elseif ~isfolder('logs')
                mkdir('logs')
            end
            diary(sprintf('logs/debug/%s_%s.log', xp.name, string(datetime('now', Format="uuuuMMdd"))));     % a basic log of command line trash

            if ~xp.debug            % unless we operate in debug mode, we disable mouse cursor and keyboard input
                ListenChar(2);      % Disable keyboard input messing up in the command window/script
                HideCursor();       % Hiding mouse cursor
            end

            xp.screen.init;         % initialise screen --- we have preset configuration already
            Screen('BlendFunction', xp.screen.win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');   % enable transparency

            xp.sound.init;          % initialise sound

            fprintf('\n****************************************\nExperiment %s\n',xp.name);
            fprintf('%s\n',string(datetime('now', Format='uuuu-MM-dd''T''HH:mm:ss.SSS')));
            fprintf('Subject %s\n\n',xp.subject);

            xp.eyetracker.screen = xp.screen;
            xp.eyetracker.trial = xp.trial;
            if isa(xp.eyetracker, 'EyelinkControlClassBase')
                xp.eyetracker.calib_pahandle = xp.sound.pahandle;
            end
            xp.log.trial = xp.trial;
            fprintf("Note: the offset GetSecs - posixtime is %.4f\n", GetSecs - posixtime(datetime('now')))

        end

        %class destructor
        function delete(xp)
            % stuff
            xp.image.delete();
            xp.sound.delete();
            xp.trial.delete();
            xp.screen.delete();
            xp.eyetracker.delete();
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
        function time = flip(xp,time,dontclear, roi_, colour_, text_)
            % tic
            if nargin < 2 || isempty(time)
                time = 0;
            end
            if nargin < 3 || isempty(dontclear)
                dontclear = 0;
            end
            if nargin < 4
                roi_ = [];
                colour_ = [];
            end
            if nargin < 6
                text_ = '';
            end
            % for mirroring: 
            % 1. we copy the content of the main presentation screen to an off-window bound to it; 
            % 2. we copy the off-window to an off-window bound to the mirror-screen
            % 3. we draw gaze (and other stuff if needed) on the off-window of the mirror-screen
            % 4. we copy the off-window to the main window of the mirror-screen
            % if ~isempty(xp.screen.mirror)
            %     Screen('CopyWindow',xp.screen.monitor(1).win,xp.screen.monitor(1).offwin, xp.screen.monitor(1).rect, xp.screen.monitor(1).offrect)                                   % win1 -> offwin1
            % end
            % time = Screen('Flip',xp.screen.win, time, dontclear);
            if ~isempty(xp.screen.mirror)
                Screen('CopyWindow',xp.screen.monitor(1).win,xp.screen.monitor(1).offwin, xp.screen.monitor(1).rect, xp.screen.monitor(1).offrect)                                   % win1 -> offwin1
                Screen('CopyWindow',xp.screen.monitor(1).offwin,xp.screen.monitor(2).offwin, xp.screen.monitor(1).offrect, xp.screen.monitor(2).offrect)                 % offwin1 -> offwin2
                % if pupillo is used, plot gaze
                if xp.eyetracker.status && ~isempty(xp.eyetracker.last_sample)
                    pause(0.0001)
                    x = xp.eyetracker.last_sample.x(1);
                    y = xp.eyetracker.last_sample.y(1);
                    Screen('glPoint', xp.screen.monitor(2).offwin, [0 255 0], x, y, 25);
                end
                % draw roi(s)
                if xp.eyetracker.status && isa(xp.eyetracker, 'PupilloControlClassBase')
                    roi_ = [roi_ xp.eyetracker.roiCalib];
                    colour_ = [colour_; xp.eyetracker.roiColour];
                    xp.eyetracker.roiCalib = [];
                    xp.eyetracker.roiColour = [];
                end
                if ~isempty(roi_)
                    Screen('FrameRect', xp.screen.monitor(2).offwin, colour_, roi_);
                end
                if ~isempty(text_)
                    Screen('DrawText', xp.screen.monitor(2).offwin, text_, 100, 100);
                end
                Screen('CopyWindow',xp.screen.monitor(2).offwin,xp.screen.monitor(2).win, xp.screen.monitor(2).offrect, xp.screen.monitor(2).rect)     % offwin2 -> win2
            end
            % toc
            time = Screen('Flip',xp.screen.win, time, dontclear);
            if xp.screen.mirror > 0
                Screen('Flip',xp.screen.monitor(xp.screen.mirror).win, time, dontclear);
            end
            % if ~isempty(xp.screen.mirror)
            %     if xp.eyetracker.status && isa(xp.eyetracker, 'PupilloControlClassBase')
            %         roi_ = [roi_ xp.eyetracker.roiCalib];
            %         colour_ = [colour_; xp.eyetracker.roiColour];
            %         xp.eyetracker.roiCalib = [];
            %         xp.eyetracker.roiColour = [];
            %     end
            %     xp.screen.draw_roi = roi_;
            %     xp.screen.draw_colour = colour_;
            %     xp.screen.draw_text = text_;
            % end
        end
        % MOVING TO EYETRACKER "INTERFACE" AS METHOD
        function updateGaze(xp)
            % updates the gaze
            if ~isempty(xp.screen.mirror)
                % Screen('CopyWindow',xp.screen.monitor(1).win,xp.screen.monitor(1).offwin, xp.screen.monitor(1).rect, xp.screen.monitor(1).offrect)                                   % win1 -> offwin1
                Screen('CopyWindow',xp.screen.monitor(1).offwin,xp.screen.monitor(2).offwin, xp.screen.monitor(1).offrect, xp.screen.monitor(2).offrect)                 % offwin1 -> offwin2
                % if pupillo is used, plot gaze
                if xp.eyetracker.status && ~isempty(xp.eyetracker.last_sample)
                    pause(0.0001)
                    x = xp.eyetracker.last_sample.x(1);
                    y = xp.eyetracker.last_sample.y(1);
                    Screen('glPoint', xp.screen.monitor(2).offwin, [0 255 0], x, y, 25);
                end
                % draw roi(s)
                if ~isempty(xp.screen.draw_roi)
                    Screen('FrameRect', xp.screen.monitor(2).offwin, xp.screen.draw_colour, xp.screen.draw_roi);
                end
                if ~isempty(xp.screen.draw_text)
                    Screen('DrawText', xp.screen.monitor(2).offwin, xp.screen.draw_text, 100, 100);
                end
                Screen('CopyWindow',xp.screen.monitor(2).offwin,xp.screen.monitor(2).win, xp.screen.monitor(2).offrect, xp.screen.monitor(2).rect)     % offwin2 -> win2
                Screen('Flip',xp.screen.monitor(xp.screen.mirror).win, 0, dontclear);
            end
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


            if xp.eyetracker.status
                xp.eyetracker.cleanup;
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
