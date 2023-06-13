function syssetMonitor(idMonitor)
arguments
    idMonitor   string  {mustBeMember(idMonitor,["eyelink" "tv"])}
end
% uses "xrandr" to adjust screen resolution to fit to specific target monitor, and sets that monitor as primary
% currently supports "eyelink" for the eyelink monitor on the right, "tv" for the big tv on the left
% and "other" for whatever
% Note: this is tailored to our exact current configuration of monitors and should be changed in a different setup!
if IsLinux
    if idMonitor == "eyelink"
        system("xrandr --screen 1 --output HDMI-A-1 --mode 1280x1024");
        system("xrandr --screen 1 --output DisplayPort-1 --primary");
    elseif idMonitor == "tv"
        system("xrandr --screen 1 --output HDMI-A-1 --mode 1920x1080");
        system("xrandr --screen 1 --output HDMI-A-1 --primary");
    end
    pause(0.4)
end