function DrawAllCards(xp, stateCards, rectCards, angle)

% stateCards: 0 down, 1 highlighted, 2  up, 3 up & highlighted
% we should improve using Screen('DrawTextures')
if nargin < 3 || isempty(rectCards)
    if length(stateCards) <= 3  % get default card rects for regular trials (3 cards)
        rectCards = round(xp.settings.rectCards);
    else                        % get default card rects for FamFlip trials (9 cards)
        famRects  = (length(xp.screen.rect)-1-9*2:length(xp.screen.rect)-2-9);
        rectCards = round(xp.screen.rect(:,famRects));
    end
end

if nargin<4 || isempty(angle)
    angle = zeros(size(stateCards));
end

Screen('DrawTexture', xp.screen.win, xp.image.texture{1,1}, [], xp.screen.rect(:,1));        % background

for iObject = 1:length(stateCards)
    tx = xp.image.texture{3,stateCards(iObject)+1};
    Screen('DrawTexture', xp.screen.win, tx, [], rectCards(:,iObject)', angle(iObject), []); % card frame
    if stateCards(iObject) >= 2                                                
        rect = rectCards(:,iObject) + xp.settings.padding;                                   % card content if up
        tx = xp.image.texture{5,xp.settings.idStim(iObject)};
        Screen('DrawTexture', xp.screen.win, tx, [], rect,angle(iObject));
    end
end


end