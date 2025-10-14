function callbackPupilloTcp(client, ~)
persistent time_mirror_update       % variable keeping track of updating the mirror screen with the gaze position through this callback on gaze data received from pupillo
if client.NumBytesAvailable
    if isempty(time_mirror_update), time_mirror_update=GetSecs; end % sets the variable the first time the callback is called
    pupillo = client.UserData;
    json = client.read(client.NumBytesAvailable, 'char');
    json = strsplit(json, '}{'); % pupillo does not send newlines...                json{1}(1) = [];
    json{end}(end) = [];
    json{1}(1) = [];
    json = ['{' json{end} '}'];   % we get only the last packet
    data = jsondecode(json);
    % counter for samples received from pupillo
    if ~isempty(pupillo.last_sample)
        nSample = pupillo.last_sample.nSample + 1;
    else
        nSample=1;
    end
    % convert gaze from (0,1) relative position to pixels; set missing values
    if data.s0.gaze.x==-1 || data.s0.gaze.y==-1   % original pupillo missing values
        x=pupillo.MISSING_DATA;
        y=pupillo.MISSING_DATA;
    else
        x=round(data.s0.gaze.x*pupillo.screen_width);
        y=round(data.s0.gaze.y*pupillo.screen_height);
    end
    % update the pupillo object with the new gaze info
    pupillo.last_sample = struct(eye_used=0, time=data.t/1000 + pupillo.offset_getsecs, x=x, y=y, nSample=nSample);
    pause(0.0001)
    if time_mirror_update - GetSecs > 0.06
        pupillo.updataGaze;
    end
end
end