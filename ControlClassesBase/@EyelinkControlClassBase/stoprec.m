function stoprec(eyelink)
if eyelink.status        
    % Write message to EDF file to mark time when blank screen is presented
    Eyelink('Message', 'BLANK_SCREEN');
    % Write !V CLEAR message to EDF file: creates blank backdrop for DataViewer
    % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Simple Drawing
    Eyelink('Message', '!V CLEAR %d %d %d', round(eyelink.settings.backgroundcolour(1)*255), round(eyelink.settings.backgroundcolour(1)*255), round(eyelink.settings.backgroundcolour(1)*255));

    % Stop recording eye movements at the end of each trial
    WaitSecs(0.05); % Add 100 msec of data to catch final events before stopping
    Eyelink('StopRecording'); % Stop tracker recording
    WaitSecs(0.005); % Allow some time for recording to stop
    varN = length(eyelink.trial.varNames);
    for v = 1:varN
        thisvarname = eyelink.trial.varNames{v};
        thisvalue = eyelink.trial.varValue.(thisvarname); % in the future we change this to a trial property (all values computed in the end or beginning of trial, or both)
        if isnumeric(thisvalue)
            thisvalue = num2str(thisvalue);
        end
        thismessage = sprintf('!V TRIAL_VAR %s %s', thisvarname, thisvalue);
        eyelink.write(thismessage);       
    end
    % Write TRIAL_RESULT message to EDF file: marks the end of a trial for DataViewer
    % See DataViewer manual section: Protocol for EyeLink Data to Viewer Integration > Defining the Start and End of a Trial
    eyelink.write('TRIAL_RESULT 0');
end