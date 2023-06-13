function syssetWifi(status)
arguments
    status string {mustBeMember(status, ["on" "off"])}
end
% turns wifi on/off
if IsLinux
    result = system("nmcli radio wifi " + status);
    
    if result == 0
        disp("system: Wifi turned " + status)
    else
        warning("system: unknown error turning wifi " + status)
    end
end

