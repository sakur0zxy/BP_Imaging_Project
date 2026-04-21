function log = logger(logFile)
%LOGGER 终端 + 文件双写日志。

fid = [];
if nargin >= 1 && ~isempty(logFile)
    ensure_dir(fileparts(logFile));
    fid = fopen(logFile, 'a');
end

log.info = @(message, varargin) localWrite('INFO', message, varargin{:});
log.warn = @(message, varargin) localWrite('WARN', message, varargin{:});
log.error = @(message, varargin) localWrite('ERROR', message, varargin{:});
log.close = @localClose;

    function localWrite(level, message, varargin)
        lineText = sprintf(message, varargin{:});
        stamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss'));
        fullText = sprintf('[%s] [%s] %s', stamp, level, lineText);
        fprintf('%s\n', fullText);
        if ~isempty(fid) && fid > 0
            fprintf(fid, '%s\n', fullText);
        end
    end

    function localClose()
        if ~isempty(fid) && fid > 0
            fclose(fid);
            fid = [];
        end
    end
end

