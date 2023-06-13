This folder contains scripts to replace the Eyelink's scripts for psychtoolbox, changing the way the sound is presented to make it compatible and stable with newer psychtoolbox versions.

Just copy these files in "/usr/share/psychtoolbox-3/PsychHardware/EyelinkToolbox/EyelinkBasic" in linux default location, or similar path otherwise

An alternative is just to copy these files to the currrent directory you run the experiment from (and they will shadow the original eyelink's files")

Note: before anything you must first install the custom eyelink toolbox from [eyelink's website](https://www.sr-research.com/support/thread-49.html), then manually resolve the path issues if the automatic script fails to do that (you have to move the psychhardware/eyelink paths bellow the psychbasic paths, use pathtool in an instance of matlab you are logged in as admin). These are the scripts that allow for video-calibration in the first place.
