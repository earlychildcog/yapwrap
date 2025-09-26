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
    properties (Hidden)
        time_mirror_update
        draw_roi
        draw_colour
        draw_text
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

        function time = flip(screen,time,dontclear, roi_, colour_, text_)

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
            if ~isempty(screen.mirror)
                Screen('CopyWindow',screen.monitor(1).win,screen.monitor(1).offwin, screen.monitor(1).rect, screen.monitor(1).offrect)                                   % win1 -> offwin1
            end
            time = Screen('Flip',screen.win, time, dontclear);
            if ~isempty(screen.mirror)
                % if screen.eyetracker.status && isa(screen.eyetracker, 'PupilloControlClassBase')
                %     roi_ = [roi_ screen.eyetracker.roiCalib];
                %     colour_ = [colour_; screen.eyetracker.roiColour];
                %     screen.eyetracker.roiCalib = [];
                %     screen.eyetracker.roiColour = [];
                % end
                screen.draw_roi = roi_;
                screen.draw_colour = colour_;
                screen.draw_text = text_;
            end
        end
        function flipMirror(screen)
            if ~isempty(screen.mirror)
                % Screen('CopyWindow',xp.screen.monitor(1).win,xp.screen.monitor(1).offwin, xp.screen.monitor(1).rect, xp.screen.monitor(1).offrect)                                   % win1 -> offwin1
                Screen('CopyWindow',screen.monitor(1).offwin,screen.monitor(2).offwin, screen.monitor(1).offrect, screen.monitor(2).offrect)                 % offwin1 -> offwin2
                % % if pupillo is used, plot gaze
                % if xp.eyetracker.status && ~isempty(xp.eyetracker.last_sample)
                %     pause(0.0001)
                %     x = xp.eyetracker.last_sample.x(1);
                %     y = xp.eyetracker.last_sample.y(1);
                %     Screen('glPoint', xp.screen.monitor(2).offwin, [0 255 0], x, y, 25);
                % end
                % draw roi(s)
                if ~isempty(screen.draw_roi)
                    Screen('FrameRect', screen.monitor(2).offwin, screen.draw_colour, screen.draw_roi);
                end
                if ~isempty(screen.draw_text)
                    Screen('DrawText', screen.monitor(2).offwin, screen.draw_text, 100, 100);
                end
                Screen('CopyWindow',screen.monitor(2).offwin,screen.monitor(2).win, screen.monitor(2).offrect, screen.monitor(2).rect)     % offwin2 -> win2
                Screen('Flip',screen.monitor(screen.mirror).win, 0, dontclear);
            end
            
        end


    end
end