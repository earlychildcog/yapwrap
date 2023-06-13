classdef KeyControlClassBase < handle
    %KEYCONTROLCLASS Summary of this class goes here
    %   Detailed explanation goes here

    properties
        status      logical = false
        index
        commands
        keyStrings = {};
        keyNums
        key
    end

    methods
        function keyboard = KeyControlClassBase(status)
            if nargin > 0 && status
                keyboard.init;
            end
        end

        function init(keyboard)
            % get keys
            KbName('UnifyKeyNames');

            % get key numbers from key strings (if configuration exists)
            keyboard.keyNums = cellfun(@KbName,keyboard.keyStrings);

            % get the key commands (may be depreciated in the future if not useful)
            if isempty(keyboard.commands)
                keyboard.commands = keyboard.keyStrings;
            end
            assert(length(keyboard.commands) == length(keyboard.keyStrings), 'commands and key amounts should match')
            keysN = length(keyboard.keyStrings);
            for k = 1:keysN
                keyboard.key.(keyboard.keyStrings{k}) = keyboard.keyNums(k);
            end
        end

        function ctrl = isKey(keyboard,key)
            [ ~ , ~ , keyCode ] = KbCheck;
            if ~isnumeric(key)
                kc = KbName(key);
            else
                kc = key;
            end
            ctrl = keyCode(kc);
        end
    end
end

