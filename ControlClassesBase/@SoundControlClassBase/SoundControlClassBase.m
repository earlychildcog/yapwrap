classdef SoundControlClassBase < handle
    % controls audio for the experiment

    properties
        status                      logical = false
        stereo                              = false;
        nameAudioDevice                     = "Speakers (Realtek(R) Audio)"
        pahandle0                           = [];
        pahandleWorker                      = [];
        fs                                  = 48000;
        folder                              = 'stimuli/sounds'
        subfolders  % automatic
        filenames   % automatic
        data        % the audio data to play (automatic)
        which      %(1,2) double % id of the sound to play
        when                                = 0;
        volume                              = 1;
    end

    methods

        function sound = SoundControlClassBase(status)
            if nargin > 0 && status
                sound.init;
            end
        end

        function delete(sound)
        end

        function init(sound)
            sound.status = true;
            InitializePsychSound(1);

            % set audio device automatically based on name
            if IsLinux
                idAudiodevice = sound.getIdSoundDevice;
            elseif IsWin
                % sound.nameAudioDevice = "50UHD_LCD_TV"; %% "HP P34hc G4 (NVIDIA High Defini"; % "Headphones (Realtek(R) Audio)";
                idAudiodevice = sound.getIdSoundDevice;
            else
                idAudiodevice = [];
            end

            % open sound device
            % sound.pahandle = PsychPortAudio('Open', idAudiodevice, 1, [], sound.fs, sound.stereo + 1);
            
            try
                sound.pahandle0 = PsychPortAudio('Open', idAudiodevice, 9, [], sound.fs, sound.stereo + 1);
            catch % was it not close properly?
                PsychPortAudio('Close');
                
                sound.pahandle0 = PsychPortAudio('Open', idAudiodevice, 9, [], sound.fs, sound.stereo + 1);
            end


            PsychPortAudio('Start', sound.pahandle0, 0, 0, 1);
            PsychPortAudio('Volume', sound.pahandle0, 1);


            % audio filenames to read
            [sound.filenames, sound.subfolders] = getSubfolderStructure(sound.folder,'wav');

            % read the audio data to memory
            sound.load();
            sound.spawnWorkers();
        end

        function load(sound)   %loading sounds

            for s = 1:length(sound.subfolders)
                thispath = [sound.folder '/' sound.subfolders{s}];
                fprintf('loading sounds from %s\n',thispath)
                for f = 1:length(sound.filenames{s})
                    thisfile = sound.filenames{s}{f};
                    [audio, thisfs] = audioread(thisfile);

                    % correct stereo/mono sound properties
                    if ~sound.stereo && size(audio,2) == 2
                        audio = mean(audio,2);
                    elseif sound.stereo && size(audio,1) == 1
                        audio = repmat(audio,[1 2]);
                    end
                    sound.data{s,f} = audio';
                    % check fs is the same as out preset fs
                    assert(sound.fs == thisfs, 'sampling frequency of audio sample %s is %d, while %d expected' , thisfile,thisfs,sound.fs)
                end
            end
        end

        function spawnWorkers(sound)    % for better performance (had issues with bop in bip-bop :/)
            sound.pahandleWorker = zeros(size(sound.data));
            for rowWorker = 1:size(sound.pahandleWorker,1)
                for colWorker = 1:size(sound.pahandleWorker,2)
                    if ~isempty(sound.data{rowWorker, colWorker})
                        sound.pahandleWorker(rowWorker, colWorker) = PsychPortAudio('OpenSlave', sound.pahandle0, 1, sound.stereo + 1);
                        PsychPortAudio('FillBuffer', sound.pahandleWorker(rowWorker, colWorker), sound.data{rowWorker, colWorker});
                    end
                end
            end
        end

        function time = play(sound, row, col, opts)
            arguments
                sound SoundControlClassBase
                row
                col
                opts.repeat = 1
                opts.when = 0;
                opts.wait = 0;
            end
            if sound.pahandleWorker(row,col) > 0
                PsychPortAudio('Volume', sound.pahandle0, sound.volume);
                time = PsychPortAudio('Start', sound.pahandleWorker(row, col), opts.repeat, opts.when, opts.wait);
            else
                warning('no sound to play')
            end
        end
        function stop(sound, row, col)  % stop all workers in the specific row and col intersection; put a row and empty column to stop the full row. Empty or no arguments to stop all
            arguments
                sound SoundControlClassBase
                row (1,:) = 1:size(sound.pahandleWorker,1)
                col (1,:) = 1:size(sound.pahandleWorker,2)
            end
            if isempty(row)
                row = 1:size(sound.pahandleWorker,1);
            end
            if isempty(col)
                col = 1:size(sound.pahandleWorker,2);
            end
            for iRow = row
                for iCol = col
                    if sound.pahandleWorker(iRow,iCol) > 0        % make sure it is a handle indeed and not uninitialised
                        PsychPortAudio('Stop', sound.pahandleWorker(iRow,iCol));
                    end
                end
            end
        end
        function id = getIdSoundDevice(sound)
            devices = PsychPortAudio('GetDevices');
            goodnames = contains(string({devices.DeviceName}), sound.nameAudioDevice);
            if ~any(goodnames)
                warning("no sound device found; empty return")
                id = [];
            else
                id = devices(find(goodnames,1)).DeviceIndex;
            end

        end
    end
end

