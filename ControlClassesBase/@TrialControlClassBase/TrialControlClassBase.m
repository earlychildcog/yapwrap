classdef TrialControlClassBase < handle
    %TRIALCONTROLCLASS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        status                      logical = false
        no                                  = 0;
        nTrial                              = 0;
        type                                = '';
        condition                           = '';
        stimtype                            = '';
        stimname                            = '';
        stimdur                             = [];
        isi                                 = 0;
        fullpath                            = '';
        attget;
        videoList
        videoName
        sequence                            = [];
        currstim                            = [];
        varNames                            = {};           % to store the variables to send
        varValue                            = struct;
        result                              = '';
        sideRevealed                        = string([]);
        flagResult                          = logical([]);

        
    end
    
    methods
        function trial = TrialControlClassBase
        end
        
        function next(trial)
            trial.no = trial.no + 1;
            trial.currstim = trial.sequence(:,trial.no);
            trial.result = '';
            % block settings change
%             trial.block.blockTrial = trial.block.blockTrial + 1;
%             if trial.block.blockTrial > trial.block.blockTrialN || trial.no == 1
%                 trial.block.next;
%             end
        end

        function varInit(trial, varNames, varValues)
            arguments
                trial TrialControlClassBase
                varNames cell
                varValues cell = num2cell(nan(size(varNames)))
            end
            trial.varNames = varNames;
            for iVar = 1:length(varNames)
                trial.varValue.(varNames{iVar}) = varValues{iVar};
            end
        end

        function varReset(trial)
            trial.varValue = structfun(@(z)NaN,trial.varValue,'UniformOutput',false);
        end

        function delete(trial)
        end
    end
end

