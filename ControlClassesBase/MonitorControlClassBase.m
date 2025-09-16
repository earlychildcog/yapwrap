classdef MonitorControlClassBase
    properties
        status  logical = false
        % onscreen window
        win
        nr
        rect
        flipInterval
        backcolour = [125 125 125]/255;
        % offscreen window
        offwin
        offrect
    end
    methods
        function monitor = MonitorControlClassBase(nr)
            if nargin > 0
                monitor.status = true;
                monitor.nr = nr;
                monitor = monitor.init;
            end
        end
        function monitor = init(monitor)
            


            %% open onscreen window
            att_count = 0;
            err_count = 0;
            max_errors = 5;
            while att_count == err_count && err_count <= max_errors
                try
                    [monitor.win, monitor.rect] = PsychImaging('OpenWindow', monitor.nr, monitor.backcolour,[],32, 2, 0);
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
                [monitor.win, monitor.rect] = PsychImaging('OpenWindow', monitor.nr, monitor.backcolour,[],32, 2, 0);
            end


            monitor.flipInterval      = Screen('GetFlipInterval',monitor.win);     %get half the refresh interval of the screen
            
            %% open offscreen window
            [monitor.offwin, monitor.offrect] = Screen('OpenOffscreenWindow', monitor.win);


        end
    end
end