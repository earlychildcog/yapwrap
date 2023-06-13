classdef EegControlClassBase < handle
    properties
            % eeg settings
        status          logical = false
        NetStationHost  = '10.10.10.42';
        NTPServer       = '10.10.10.51';
        syncinterval    = 60;
        lastSync = -Inf;
        screen          ScreenControlClassBase = ScreenControlClassBase         % points to the screen
        eventTime = zeros(10^4,1)
        eventName = cell(10^4,1)
        eventCount = 0;
        eventTimeMulti = 0;
    end
    methods
        function  eeg = eegControlClassBase(status)

            if nargin == 0 || ~status
                return
            else
                eeg.init
            end
        end
        function init(eeg)
            eeg.status = true;
            NetStation('Connect',eeg.NetStationHost);
            NetStation('GetNTPSynchronize', eeg.NTPServer);
            WaitSecs(.5);
            fprintf('eeg synced\n')
        end
        function startrec(eeg)
            if eeg.status
                NetStation('StartRecording');
            end
        end
        function stoprec(eeg)
            if eeg.status
                NetStation('StopRecording');
            end
        end
        function disconnect(eeg)
            if eeg.status
                NetStation('Disconnect');
            end
        end
        function sync(eeg, force)
            if eeg.status
                if nargin == 1
                    if (GetSecs - eeg.lastSync > eeg.syncinterval)
                        NetStation('Synchronize',eeg.screen.win);
                        eeg.lastSync = GetSecs;
                    end
                elseif force
                    NetStation('Synchronize',eeg.screen.win);
                    eeg.lastSync = GetSecs;
                end
            end
        end
        function eventSave(eeg, name, time)
            % saves events to send later to netstation
            eeg.eventCount = eeg.eventCount + 1;
            eeg.eventName{eeg.eventCount} = name;
            if nargin > 2
                eeg.eventTime(eeg.eventCount) = time;
            else
                eeg.eventTime(eeg.eventCount) = GetSecs;
            end
        end
        function eventSaveMultiIntoOne(eeg, name, time)
            % saves events (ie key presses) that last for some time but we want to send only their onset
            % to do: report the duration of the event based on how long a key is pressed
            if time - eeg.eventTimeMulti > 0.2
                eeg.eventSave(name, time)
            end
            eeg.eventTimeMulti = time;
        end
        function eventSend(eeg, varargin)
            if eeg.status
                fprintf('eeg triggers %d\n', eeg.eventCount)
                for iEvent = 1:eeg.eventCount
                    name = eeg.eventName{iEvent};
                    time = eeg.eventTime(iEvent);
                    NetStation('Event', name, time, 0.1 ,varargin{:});
                end
                eeg.eventReset;
            end
        end
        function eventReset(eeg)
            eeg.eventCount = 0;
          	eeg.eventTime = zeros(10^4,1);
            eeg.eventName = cell(10^4,1);
        end
    end
end