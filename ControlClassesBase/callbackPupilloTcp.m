
function gaze = callbackPupilloTcp(client, event)
if client.NumBytesAvailable
    pupillo = client.UserData;
    json = client.read(client.NumBytesAvailable, 'char');
    json = strsplit(json, '}{'); % pupillo does not send newlines...                json{1}(1) = [];
    json{end}(end) = [];
    json{1}(1) = [];
    json = ['{' json{end} '}'];   % we get only the last packet
    data = jsondecode(json);
    if ~isempty(pupillo.last_sample), nSample = pupillo.last_sample.n + 1; else nSample=1; end
    if data.s0.gaze.x==-1 || data.s0.gaze.y==-1   % original pupillo missing values
        x=pupillo.MISSING_DATA;
        y=pupillo.MISSING_DATA;
    else
        x=round(data.s0.gaze.x*pupillo.screen_width);
        y=round(data.s0.gaze.y*pupillo.screen_height);
    end
    gaze = struct(eye_used=0, time=data.t, x=x, y=y, n=nSample);
    pupillo.last_sample = gaze;
    pause(0.0001)
end
end