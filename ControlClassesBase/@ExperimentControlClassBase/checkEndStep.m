function flagResult = checkEndStep(xp,flagResult, timeStepStart, durMax)

if GetSecs-timeStepStart>durMax
    flagResult = -4;
end

end