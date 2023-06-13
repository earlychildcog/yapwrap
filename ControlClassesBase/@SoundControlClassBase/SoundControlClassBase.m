classdef SoundControlClassBase < handle
    %SOUNDCONTROLCLASS Summary of this class goes here
    %   Detailed explanation goes here

    properties
        status                      logical = false
        stereo                              = false;
        nameAudioDevice                     = "AG06"
        pahandle                            = [];
        fs                                  = 48000;
        folder                              = 'stimuli/sounds'
        subfolders
        filenames
        data
        which
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
            if IsLinux
                idAudiodevice = getIdSoundDevice;
            else
                idAudiodevice = [];
            end
            sound.pahandle = PsychPortAudio('Open', idAudiodevice, 1, [], sound.fs, sound.stereo + 1);
            [sound.filenames, sound.subfolders] = getSubfolderStructure(sound.folder,'wav');
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

        function time = play(sound, when, wait)
            if nargin < 2
                when = 0;
            end
            if nargin < 3
                wait = 1;
            end
            PsychPortAudio('Volume', sound.pahandle, sound.volume);
            PsychPortAudio('FillBuffer', sound.pahandle, sound.which);
            time = PsychPortAudio('Start', sound.pahandle,[],when, wait);
        end
        function stop(sound)
            PsychPortAudio('Stop', sound.pahandle);
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

