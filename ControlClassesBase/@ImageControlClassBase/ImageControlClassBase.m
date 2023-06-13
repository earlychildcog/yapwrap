classdef ImageControlClassBase < handle
    %IMAGECONTROLCLASS Summary of this class goes here
    %   Detailed explanation goes here
    % I should better change this: instead of folder/subfolder...
    % (like who cares? we convert images to textures in adcanve)...
    % we should have sth like: image data (texture pointers) name, and conditions related to each
    
    properties
        folder          = 'stimuli/images'
        subfolders
        filenames
        screen         ScreenControlClassBase         % pointer to screen being used
        texture                 % texture pointers to screen
    end
    
    methods
        function image = ImageControlClassBaseBase
        end

        function delete(image)
        end

        function load(image)
            if ~isempty(image.subfolders)
                for s = 1:length(image.subfolders)
                    thispath = [image.folder '/' image.subfolders{s}];
                    fprintf('loading images from %s\n',thispath)
                    for f = 1:length(image.filenames{s})
                        thisfile = image.filenames{s}{f};
                        [I] = imread(thisfile);
                        [~, ~, alpha] = imread(thisfile);
                        % put background colour if transparent, bad fix?
                        % let's be careful here!!!!
                        if ~isempty(alpha)
                            I  = I + (255-repmat(alpha,[1 1 3]))*image.screen.backcolour(1);
                            I(:,:,4) = alpha;
                        end
                        image.texture{s,f} = Screen('MakeTexture',image.screen.win,I);
                    end
                end
            elseif ~isempty(image.folder)
                [filenames_, subfolders_] = getSubfolderStructure(image.folder, '.png');
                image.subfolders = subfolders_;
                image.filenames = filenames_;
                image.load;
            end
        end
        function draw(image,txtpoint,rectID)
            if nargin < 3 || rectID == 0
                rect = image.screen.full;
            else
                rect = image.screen.rect(:,rectID);
            end
            Screen('DrawTexture', image.screen.win, txtpoint, [], rect);
        end
    end
end

