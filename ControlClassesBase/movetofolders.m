files = arrayfun(@(x)x.name,dir('*.m'),'UniformOutput',false);

for f = files'
    fn = f{1}
    fold = ['@' char(extractBefore(fn,'.m'))];
    mkdir(fold);
    copyfile(fn, [fold '/' fn])
end



