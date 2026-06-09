-- Syntax highlighting for code-trace buffers
local M = {}

function M.setup(buf)
  -- Set up syntax matching
  vim.cmd([[
    syntax clear
    
    " Comments (lines starting with #)
    syntax match codetraceComment "^#.*$"
    
    " Indentation markers
    syntax match codetraceIndent "^\s\+"
    
    " Trace markers (-, •, *, +)
    syntax match codetraceMarker "^\s*[-•*+]\s"
    
    " Content in parentheses (description or line preview)
    syntax match codetraceDescription "([^)]\+)"
    
    " File path and line number
    syntax match codetraceFile "\~\?[/a-zA-Z0-9._-]\+\.\w\+:\d\+\s*$"
    syntax match codetraceFilePath "\~\?[/a-zA-Z0-9._-]\+\.\w\+" contained containedin=codetraceFile
    syntax match codetraceLineNum ":\d\+\s*$" contained containedin=codetraceFile
    
    " Level-based indentation (optional: different colors for different levels)
    syntax match codetraceLevel0 "^[-•*+]" nextgroup=codetraceDescription
    syntax match codetraceLevel1 "^\s\{2\}[-•*+]" nextgroup=codetraceDescription
    syntax match codetraceLevel2 "^\s\{4\}[-•*+]" nextgroup=codetraceDescription
    syntax match codetraceLevel3 "^\s\{6,\}[-•*+]" nextgroup=codetraceDescription
    
    " Highlight groups
    highlight default link codetraceComment Comment
    highlight default link codetraceMarker Special
    highlight default link codetraceDescription String
    highlight default link codetraceFilePath Directory
    highlight default link codetraceLineNum Number
    highlight default link codetraceIndent NonText
    
    " Level-specific colors (optional, can be customized)
    highlight default link codetraceLevel0 Special
    highlight default link codetraceLevel1 Special
    highlight default link codetraceLevel2 Special
    highlight default link codetraceLevel3 Special
  ]])
end

return M
