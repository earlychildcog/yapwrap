classdef PupilloControlClassBase < handle
    properties
        status          logical = false
        dummy           = 0
        ip              char = 'localhost'
        port            double = 4799
        client
        eventTime = zeros(10^4,1)
        eventName = cell(10^4,1)
        eventCount = 0;
        eventTimeMulti = 0;
        calibrationFilename string = "doc/calibration.csv"
        calibrationTable table
        roiCalib        % the roi around the calibration point for drawing on control screen
        roiColour
        buttonCalib = KbName('SPACE')
        screen_width = 1920;
        screen_height = 1080;
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
                pupillo.client.UserData = [0 NaN NaN NaN]; % new or old, time, x, y
                pupillo.client.configureCallback("byte", 1, @callbackPupilloTcp);
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
        function [eye_used, evt] = getGaze(~)
            while Eyelink('NewFloatSampleAvailable') == 0 % waiting for sample...
            end
            eye_used = Eyelink('EyeAvailable');
            evt = Eyelink('NewestFloatSample');
            if eye_used == 2
                eye_used = [0 1];
            end
        end
        function eventSave(pupillo, name, time)
            if pupillo.status
                % saves events to send later to netstation
                pupillo.eventCount = pupillo.eventCount + 1;
                pupillo.eventName{pupillo.eventCount} = name;
                if nargin > 2
                    pupillo.eventTime(pupillo.eventCount) = time;
                else
                    pupillo.eventTime(pupillo.eventCount) = GetSecs;
                end
            end
        end
        function eventSaveMultiIntoOne(pupillo, name, time)
            if pupillo.status
                % saves events (ie key presses) that last for some time but we want to send only their onset
                % to do: report the duration of the event based on how long a key is pressed
                if time - pupillo.eventTimeMulti > 0.2
                    pupillo.eventSave(name, time)
                end
                pupillo.eventTimeMulti = time;
            end
        end
        function eventSend(pupillo, varargin)
            if pupillo.status
                fprintf('eeg triggers %d\n', pupillo.eventCount)
                for iEvent = 1:pupillo.eventCount
                    name = pupillo.eventName{iEvent};
                    time = pupillo.eventTime(iEvent);
                    NetStation('Event', name, time, 0.1 ,varargin{:});
                end
                pupillo.eventReset;
            end
        end
        function eventSendAll(pupillo, varvalues)
            % send all variables at once
            arguments
                pupillo
                varvalues   struct
            end
            if pupillo.status
                names = fieldnames(varvalues);
                values = struct2cell(varvalues);
                values(cellfun(@islogical, values)) = cellfun(@double,values(cellfun(@islogical,values)), UniformOutput=false);     % turn logical to double
                allargin = [names values]';
                allargin = allargin(:);
                pupillo.eventSend(allargin{:});
            end
        end
        function eventReset(pupillo)
            if pupillo.status
                pupillo.eventCount = 0;
              	pupillo.eventTime = zeros(10^4,1);
                pupillo.eventName = cell(10^4,1);
            end
        end
    end
end