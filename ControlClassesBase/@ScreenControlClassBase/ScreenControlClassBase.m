classdef ScreenControlClassBase < handle
    % some description to come
    properties
        status          logical = false
        nr              = 0;        % screens to open
        mirror          = [];        % set which of the above to mirror primary monitor (1) to; empty if none
        monitor         MonitorControlClassBase = MonitorControlClassBase
        win
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
            % set which screen; can be changed before calling screen.init
            if IsLinux 
                screen.nr  = max(Screen('Screens'));
            elseif IsWin
                screen.nr  = [1 3];
                screen.mirror = 2;
            else
                screen.nr  = min(Screen('Screens'));
            end
            if nargin > 0 && status
                screen.init;
            end
        end

        function delete(screen)
        end

        function setup(screen)
            % Define black, white and grey (or/and other colours)
            

            screen.colour.black          	= BlackIndex(screen.nr(1));
            screen.colour.white             = WhiteIndex(screen.nr(1));
            screen.colour.grey          	= (screen.colour.black+screen.colour.white)/2;

            %READ the presentation screen size           
            ScreenRes           = Screen('Resolution', screen.nr(1));
            screen.width   	    = ScreenRes(1).width;
            screen.height   	= ScreenRes(1).height;
            screen.full = [0; 0; screen.width; screen.height];
        end

        function init(screen)
            screen.status = true;
            screen.setup;   % setup basic properties of screen
            Screen('Preference','SkipSyncTests',2*screen.skipsynccheck);
            ov = Screen('Preference', 'ConserveVRAM');
            %% start monitor(s)
            screen.monitor = arrayfun(@(nr)MonitorControlClassBase(nr), screen.nr);
            screen.win = screen.monitor(1).win;
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