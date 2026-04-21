function startup()
%STARTUP 把项目必要路径加入 MATLAB 搜索路径。

projectRoot = fileparts(mfilename('fullpath'));
addpath(projectRoot);
addpath(fullfile(projectRoot, 'config'));
addpath(genpath(fullfile(projectRoot, 'src')));
addpath(fullfile(projectRoot, 'tests'));
end
