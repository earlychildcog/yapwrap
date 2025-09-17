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
        last_sample   struct                 % Last sample data from eye tracker
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
end
