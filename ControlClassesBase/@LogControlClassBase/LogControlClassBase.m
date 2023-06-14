classdef LogControlClassBase < handle
    % create logfiles for stimulus presentation scripts
    % call: log = logfile(name, exp, header)
    % where $name$ is a string
    % $exp$ is a structure containing the experiment information
    % and $header$ is a cell array of strings
    % To write on file call $log.write(line)$
    % where $line$ is also a cell array of stuff
    properties
        status              logical = false
        trial               TrialControlClassBase = TrialControlClassBase
        folder string = "logs"
        filename string = string([])
        subject string = "test"
        header
        fid
    end
    methods
        function log = LogControlClassBase(pathFile, status)
            arguments
                pathFile string = string([])
                status logical = false
            end
            if ~isempty(pathFile)
                [folder, file, ext] = fileparts(pathFile);
                log.folder = folder;
                log.filename = file+ext;
            end
            if status
                log.init;
            end
        end
        function init(log, nameSession)          % initialises log file
            arguments
                log
                nameSession string = string([])
            end
            if isempty(log.trial.varNames)
                warning("init log failed: no variables to start")
                return
            end
            if ~isempty(nameSession)
                log.subject = nameSession;
            end
            log.status = true;
            if isempty(log.filename)
                log.filename = sprintf('%s_%s.log',log.subject, char(datetime('now','Format','yyyy_MM_dd_HHmm')));
            end
            log.header = ["session", string(log.trial.varNames)];
            log.fid = fopen(fullfile(log.folder,log.filename) , 'wt' );
            cellfun(@(x)fprintf(log.fid, '%s\t',x),log.header);
        end
        function result = write(log, line)      % update the log
            if log.status
                result = true;
                if nargin == 1
                    line = [log.subject, struct2cell(log.trial.varValue)'];
                end
                if length(line) ~= length(log.header)
                    warning('Writing to log file failed: line length does not match header')
                    result = false;
                    return
                end
                line(cellfun(@islogical,line)) = cellfun(@double,line(cellfun(@islogical,line)), UniformOutput=false); % convert logical values to numerical
                line = cellfun(@string,line);        % convert `line` contents to strings
                try
                    fprintf(log.fid, '\n');
                    arrayfun(@(x)fprintf(log.fid, '%s\t',x),line);
                catch
                    result = false;
                    warning('Writing to log file failed: unknown error')
                    return
                end
            end
        end
        function expr = reset(log)
            % function to reset some trial variables
            % variables to reset are stored in $vars_reset$ field
            % call $eval(log.reset)$ for command to take effect
            expr = sprintf('for v=%s.vars_reset, eval([v{1} ''= []'']); end',log.name);
        end
        function close(log)
            try
                if log.status
                    fclose(log.fid);
                end
            catch err
                warning(err.message);
            end
        end
        function delete(log)
            log.close();
        end
    end
end

