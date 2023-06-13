function [filenames, subfolders] = getSubfolderStructure(folder, ext)
arguments
    folder string {mustBeFolder}
    ext string
end
% make sure extension does not contain the dot
while ext{1}(1) == "."
    ext{1}(1) = [];
end
% function to get subfolder/file structure inside a two-levep folder structure
% NEED TO REWRITE
% Use strings ffs
% Use multiple extensions
subfolders =  dir(folder);
subfolders = arrayfun(@(x)x.name,subfolders(arrayfun(@(x)x.isdir,subfolders)),'UniformOutput',false);
subfolders(strcmp(subfolders,'.')) = [];
subfolders(strcmp(subfolders,'..')) = [];
filenames = cellfun(@(s)arrayfun(@(x)[x.folder '/' x.name],dir(fullfile(folder,s,"*."+ext)),'UniformOutput',false), subfolders,'UniformOutput',false);