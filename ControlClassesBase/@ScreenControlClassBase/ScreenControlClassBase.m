classdef ScreenControlClassBase < handle
    % some description to come
    properties
        status          logical = false
        win
        nr              = 0;
        backcolour      = [125 125 125]/255;
        colour
        width
        height
        rect            = {};
        full
        refrate
        skipsynccheck           = 1;
        monitorId        string {mustBeMember(monitorId, ["eyelink", "tv", "other"])}  = "eyelink"
    end
    methods

        function screen = ScreenControlClassBase(status)
            if nargin > 0 && status
                screen.init;
            end
        end

        function delete(screen)
        end

        function getProperties(screen)
            % Define black, white and grey (or/and other colours)
            screen.nr
            screen.colour.black          	= BlackIndex(screen.nr);
            screen.colour.white             = WhiteIndex(screen.nr);
            screen.colour.grey          	= (screen.colour.black+screen.colour.white)/2;

            %READ the presentation screen size           
            ScreenRes           = Screen('Resolution', screen.nr);
            screen.width   	    = ScreenRes(1).width;
            screen.height   	= ScreenRes(1).height;
            screen.full = [0; 0; screen.width; screen.height];
        end

        function init(screen)
            screen.status = true;
            screen.getProperties;
%             screen.nr = max(Screen('Screens'));
            Screen('Preference','SkipSyncTests',2*screen.skipsynccheck);
            % open screen window
            att_count = 0;
            err_count = 0;
            max_errors = 5;
            while att_count == err_count && err_count <= max_errors
                try
                    screen.win = PsychImaging('OpenWindow', screen.nr, screen.backcolour,[],32, 2, 0);
                catch
                    warning('screen sync failed');
                    err_count = err_count+1;
                end
                att_count = att_count + 1;
            end
            if err_count <= max_errors
                disp('window sync successful');
            else
                disp('syncronisation failed; disabling sync tests');
                Screen('Preference','SkipSyncTests', 1);
                screen.win = PsychImaging('OpenWindow', screen.nr, screen.backcolour,[],32, 2, 0);
            end
            

            screen.refrate      = Screen('GetFlipInterval',screen.win);     %get half the refresh interval of the screen
        end

        function fill(screen,colour)
            if ~exist('colour','var')
                colour = screen.backcolour;
            elseif ischar(colour)
                colour = screen.colour.(colour);
            end
            Screen('FillRect',screen.win,colour);
        end

        function time = flip(screen,time,dontclear)
            if nargin < 2 || isempty(time)
                time = 0;
            end
            if nargin < 3 || isempty(dontclear)
                dontclear = 0;
            end
            time = Screen('Flip',screen.win,time,dontclear);
        end


    end
end