classdef EyelinkControlClassBase < handle
    %EYELINKCONTROLCLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        status          double = 0
        screen          ScreenControlClassBase = ScreenControlClassBase         % points to the screen
        trial           TrialControlClassBase = TrialControlClassBase           % points to the trial structure class
        settings        % need to add option to preset in config file
        calib_video     = '';
        calib_sound     = 'stimuli/sounds/cal_bulls_eye.wav'
        calib_pahandle  = [];
        edfname         = '';
        edffolder       = 'data';
        edf
        ip              = '10.10.10.70';
        eyeused         = [];
    end
    
    methods
        function eyelink = EyelinkControlClassBaseBase(status)
            if nargin > 0 && status
                eyelink.init;
            end
        end
        
        function init(eyelink)

            eyelink.status = 1;

            % give a random name in case it is empty
            if isempty(eyelink.edfname)
                eyelink.edfname = sprintf('%.6d.edf',randi(10^6));
            end
            eyelink.screen
            eyelink.trial
            eyelink.settings = EyelinkInitDefaults(eyelink.screen.win);
            eyelink.settings.backgroundcolour = eyelink.screen.backcolour;
            eyelink.settings.calib_sound = audioread(eyelink.calib_sound)';
            eyelink.settings.calib_pahandle = eyelink.calib_pahandle;
            % Configure animated calibration target path and properties
            eyelink.settings.calTargetType    = 'video';
            
            % enter calibration video
            if isempty(eyelink.calib_video)
                calvideo = dir('stimuli/videos/01-calibration/*.avi');
                calvideo = calvideo(1);         % in case of many videos
                eyelink.calib_video = [calvideo.folder '/' calvideo.name];
            end
            eyelink.settings.calAnimationTargetFilename = eyelink.calib_video;
            eyelink.settings.targetbeep = 0;
            eyelink.settings.feedbackbeep = 0;
            eyelink.settings.calAnimationResetOnTargetMove = true; % false by default, set to true to rewind/replay video from start every time target moves
            
            % You must call this function to apply the changes made to the eye.el structure above
            EyelinkUpdateDefaults(eyelink.settings);
            
            Eyelink('SetAddress', eyelink.ip);    %Changing eyelink ip address
            % Initialization of the connection with the Eyelink Gazetracker.
            % exit program if this fails.
            if Eyelink('Initialize','PsychEyelinkDispatchCallback') < 0
                warning('Unable to connect to eyetracking host computer, we do without eyetracker');
                Eyelink('InitializeDummy','PsychEyelinkDispatchCallback')
                eyelink.status = 2;
            end
            
            [~, vs] = Eyelink('GetTrackerVersion');
            fprintf('Running experiment on a ''%s'' tracker.\n', vs );
            
            % open file to record data to
            eyelink.edfname
            eyelink.edf = Eyelink('Openfile', eyelink.edfname, 1);

            %checks if edf file was created ok
            if eyelink.edf ~= 0
                error('Cannot create EDF file ''%s'' ', eyelink.edfname);
            end
            

            % SET UP TRACKER CONFIGURATION
            % Setting the proper recording resolution, proper calibration type,
            % as well as the data file content;
            Eyelink('command', 'add_file_preamble_text ''Recorded by EyelinkToolbox conflict-study''');
            
            % This command is crucial to map the gaze positions from the tracker to
            % screen pixel positions to determine fixation
            Eyelink('command','screen_pixel_coords = %ld %ld %ld %ld', 0, 0, eyelink.screen.width-1, eyelink.screen.height-1);
            
            Eyelink('message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, eyelink.screen.width-1, eyelink.screen.height-1);
            % set calibration type.
            Eyelink('command', 'calibration_type = HV5');    
            % Allow a supported EyeLink Host PC button box to accept calibration or drift-check/correction targets via button 5
            Eyelink('Command', 'button_function 5 "accept_target_fixation"');
            % %Eyelink('command', 'animation_target = videos/calibration/cal_bulls_eye.avi');
            % Eyelink('command', 'generate_default_targets = NO');
            
            % set parser (conservative saccade thresholds)
            Eyelink('command', 'saccade_velocity_threshold = 35');
            Eyelink('command', 'saccade_acceleration_threshold = 9500');
            
            %set to track diameter
            Eyelink('command', 'pupil_size_diameter = DIAMETER');
            
            % set EDF file contents
                % 5.1 retrieve tracker version and tracker software version
            [v,vs] = Eyelink('GetTrackerVersion');
            fprintf('Running experiment on a ''%s'' tracker.\n', vs );
            vsn = regexp(vs,'\d','match');
            
            if v ==3 && str2double(vsn{1}) >= 4 % if EL 1000 and tracker version 4.xx or later
                % remote mode possible add HTARGET ( head target)
                Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
                Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT,HTARGET');
                % set link data (used for gaze cursor)
                Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
                Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT,HTARGET');
            else
                Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
                Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT');
                % set link data (used for gaze cursor)
                Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
                Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
            end
        end
        
        function delete(eyelink)
            if eyelink.status
                Eyelink('Shutdown');        %close eyetracker
            end
        end

        function calibrate(eyelink)
            if eyelink.status
                eyelink.screen.fill(eyelink.settings.backgroundcolour)
                eyelink.screen.flip(0,1)
    %             el.calAnimationTargetFilename = [pwd '/' calMovieName];
    %         el.backgroundcolour           = grey;
            % You must call this function to apply the changes made to the el structure above
                EyelinkUpdateDefaults(eyelink.settings);
        
                % Calibrate the eye tracker
                EyelinkDoTrackerSetup(eyelink.settings);
            end
        end

        function write(eyelink, message, varargin)
            if eyelink.status
                message_ = sprintf(message, varargin{:});
                Eyelink('Message', message_);
            end
        end

        function cleanup(eyelink)

            Eyelink('StopRecording');
        	Eyelink('CloseFile');
            Eyelink('Command', 'clear_screen 0'); % Clear trial image on Host PC at the end of the experiment

            try
            % download data file
                Eyelink('SetOfflineMode')
                fprintf('Receiving data file ''%s''\n', eyelink.edfname );
                status=Eyelink('ReceiveFile');
                if status > 0
                    fprintf('ReceiveFile status %d\n', status);
                end
                if 2==exist(eyelink.edfname, 'file')
                    movefile(eyelink.edfname,[eyelink.edffolder '/' eyelink.edfname])
                    fprintf('Data file ''%s'' can be found in ''%s''\n', eyelink.edfname, [pwd '/' eyelink.edffolder] );
                end
            catch rdf
                warning('Problem receiving data file ''%s''\n', eyelink.edfname );
            end
        end
    end
end

