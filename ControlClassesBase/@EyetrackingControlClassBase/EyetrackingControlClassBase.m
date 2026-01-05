classdef (Abstract) EyetrackingControlClassBase < handle
    %EYETRACKINGCONTROLCLASSBASE Abstract base class for eye tracking systems
    %   This abstract class defines the common interface and properties for
    %   different eye tracking systems like Eyelink and Pupillo.
    %   Concrete implementations must inherit from this class and implement
    %   all abstract methods.
    properties (Abstract)
        status        double                 % Eye tracker status (false=inactive, true=active)
        ip            char                   % IP address of eye tracking host
        screen        ScreenControlClassBase % Reference to screen control class
        trial         TrialControlClassBase  % Reference to trial control class
        savefile      char                   % Filename for saving eye tracking data
        last_sample   GazeSampleClass        % Last sample data from eye tracker
        MISSING_DATA  double                 % which value missing data should be in; avoid NaN
    end
    methods
        function eyetracker = EyetrackingControlClassBase()
            % Constructor for the abstract base class
            % Concrete subclasses should call their own initialization
        end
    end

    methods (Abstract)
        % Abstract methods that must be implemented by concrete subclasses

        init(eyetracker)
        % Initialize the eye tracking system
        % Should set up connection, configure settings, and set status to true
        
        newsession(eyetracker, id, path_data)
        % Start a new session. Set path for where data is saved
        
        calibrate(eyetracker, varargin)
        % Perform calibration of the eye tracking system
        % May accept optional parameters specific to the tracking system

        gaze = getgaze(eyetracker)
        % Get current gaze data from the eye tracker
        % Returns: struct with gaze information (eye_used, x, y coordinates)

        write(eyetracker, message, varargin)
        % Write message/event to eye tracking data file
        % message: string message to write
        % varargin: optional formatting arguments

        startrec(eyetracker)
        % Start recording eye tracking data
        % Should begin capturing data and set status to true

        stoprec(eyetracker)
        % Stop recording eye tracking data
        % Should stop capturing data and set status to false


    end
    methods
        function updateGaze(eyetracker)
            % updates the gaze
            if eyetracker.screen.status && ~isempty(eyetracker.screen.mirror)
                dontclear = true;
                % Screen('CopyWindow',eyetracker.screen.monitor(1).win,eyetracker.screen.monitor(1).offwin, eyetracker.screen.monitor(1).rect, eyetracker.screen.monitor(1).offrect)                                   % win1 -> offwin1
                Screen('CopyWindow',eyetracker.screen.monitor(1).offwin,eyetracker.screen.monitor(2).offwin, eyetracker.screen.monitor(1).offrect, eyetracker.screen.monitor(2).offrect)                 % offwin1 -> offwin2
                % if pupillo is used, plot gaze
                if eyetracker.status && ~isempty(eyetracker.last_sample)
                    if eyetracker.last_sample.x ~= eyetracker.MISSING_DATA
                        pause(0.0001)
                        x = eyetracker.last_sample.x(1);
                        y = eyetracker.last_sample.y(1);
                        Screen('glPoint', eyetracker.screen.monitor(2).offwin, [0 255 0], x, y, 25);
                    end
                end
                % draw roi(s)
                if ~isempty(eyetracker.screen.draw_roi)
                    Screen('FrameRect', eyetracker.screen.monitor(2).offwin, eyetracker.screen.draw_colour, eyetracker.screen.draw_roi);
                end
                if ~isempty(eyetracker.screen.draw_text)
                    Screen('DrawText', eyetracker.screen.monitor(2).offwin, eyetracker.screen.draw_text, 100, 100);
                end
                Screen('CopyWindow',eyetracker.screen.monitor(2).offwin,eyetracker.screen.monitor(2).win, eyetracker.screen.monitor(2).offrect, eyetracker.screen.monitor(2).rect)     % offwin2 -> win2
                Screen('Flip',eyetracker.screen.monitor(eyetracker.screen.mirror).win, 0, dontclear);
            end
        end
    end
end
