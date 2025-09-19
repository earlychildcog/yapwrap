classdef PupilloControlClassBase < EyetrackingControlClassBase
    properties
        status          = 0
        dummy           = 0
        ip              = 'localhost'
        port            double = 4799
        client
        savefile
        calibrationFilename string = "doc/calibration.csv"
        calibrationTable table
        roiCalib        % the roi around the calibration point for drawing on control screen
        roiColour
        buttonCalib = KbName('SPACE')
        screen_width = 1920;
        screen_height = 1080;
        screen        ScreenControlClassBase % Reference to screen control class
        trial         TrialControlClassBase  % Reference to trial control class
        settings
        MISSING_DATA = -99999   % pupillo missing values are -1, but that is because gaze normalised between 0 and 1. But we need gaze with pixel coordinates if we want to do anything with it, and in that case -1 is not a good option. So define a function that gets the gaze and converts it to appropriate pixel based format with this missing vavue if pupillo gives -1
        last_sample = struct(eye_used=0, time=posixtime(datetime('now')), x=-99999, y=-99999, n=0);
    end
    methods
        function  pupillo = PupilloControlClassBase(status)
            if nargin == 0 || ~status
                return
            else
                pupillo.init
            end
        end
        function init(pupillo)
            if ~pupillo.dummy
                pupillo.status = true;
                fprintf("Establishing connection to pupillo server...")
                pupillo.client = tcpclient(pupillo.ip, pupillo.port);
                fprintf(" Connection established\n")
                pause(0.5)
                pupillo.client.UserData = pupillo;  % we pass reference to the pupillo object itself
                pupillo.client.configureCallback("byte", 65, @callbackPupilloTcp);
                pupillo.calibrationTable = readtable(pupillo.calibrationFilename);
                pupillo.calibrationTable.stim = string(pupillo.calibrationTable.stim);
                if max(pupillo.calibrationTable{:, ["x" "y"]}, [], [1 2]) > 1            % normalise if x and y given in pixel coordinates
                    pupillo.calibrationTable{:, ["x" "y"]} = pupillo.calibrationTable{:, ["x" "y"]}./[pupillo.screen_width pupillo.screen_height];       % FIX TO CHECK DIMENSIONS FROM SOMEWHERE!!!!!
                end
            end
        end
        % in the future we will set the trial arguments automatically through the trialcontrolclass
        function startrec(pupillo, trialId, filename)
            arguments
                pupillo
                trialId string = "NULL"
                filename string = "NULL"
            end
            if pupillo.status && ~pupillo.dummy
                c = struct(a="start",p=[trialId, filename]);
                pupillo.client.write(jsonencode(c), "char")
            end
        end
        function stoprec(pupillo)
            if pupillo.status && ~pupillo.dummy
                c = struct(a="stop");
                pupillo.client.write(jsonencode(c), "char")
            end
        end
        function calibrate(pupillo, gazecoords)
            if pupillo.status
                c = struct(a="gazeCalibration", p=gazecoords);
                pupillo.client.write(jsonencode(c), "char")
            end
        end
        function checkCalib(pupillo, filenameStim, temporalIndex)
            % TO IMPROVE: separate drawing and checking!!!!!
            % filenameStim can either be the full path of the calibration stimulus, some identifier (as exists in the calibration file) or just the filename
            % temporalIndex can be frame, time etc, any ordinal temporal measure as in the calibration file
            persistent timeCalib
            if pupillo.status
                [~, stim] = fileparts(filenameStim);
                rowCalib = pupillo.calibrationTable.stim == stim & pupillo.calibrationTable.iStart <= temporalIndex & pupillo.calibrationTable.iEnd >= temporalIndex;
                if any(rowCalib)
                    xyCal = pupillo.calibrationTable{rowCalib, ["x" "y"]};
                    pupillo.roiCalib = round(([xyCal'; xyCal'] + [-0.03; -0.05; 0.03; 0.05]).*[pupillo.screen_width; pupillo.screen_height; pupillo.screen_width; pupillo.screen_height]);
                    pupillo.roiColour = [0 255 0];
                    % now check for space
                    [~, secs, keyCode] = KbCheck;
                    if keyCode(pupillo.buttonCalib) && (isempty(timeCalib) || (secs - timeCalib > 0.4))
                        pupillo.calibrate(xyCal);
                        fprintf("calibrate\n")
                        timeCalib = secs;
                    end
                    if ~isempty(timeCalib) && (secs - timeCalib < 0.4)
                        pupillo.roiColour = [255 0 0];
                    end
                else
                    pupillo.roiCalib = [];
                    pupillo.roiColour = [];
                end
            end
        end
        function gaze = getgaze(pupillo, use_last)
            arguments
                pupillo PupilloControlClassBase;
                use_last logical = true;
            end
            if use_last
                gaze = pupillo.last_sample;
            else
                gaze = callbackPupilloTcp(pupillo.client);
            end
        end
        function write(~, varargin)
            % not implemented yet, print on screen instead
            fprintf('[%s]: ', string(datetime('now', Format='uuuu-MM-dd HH:mm:ss.SSS')))
            fprintf(varargin{:})
            fprintf('\n')
        end
        function cleanup(pupillo)
            pupillo.stoprec;
        end
    end
end
