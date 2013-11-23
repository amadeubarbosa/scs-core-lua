

local IDENT_NUM = 2
local file = assert(io.open("output.html","w"))
function writeLine(file,s) file:write(s .. "\n") end

writeLine(file, [[
<head>
    <style type="text/css">
    .css-treeview ul, .css-treeview li{padding:0;margin:0;list-style:none;margin: 0 0 0 12px;}
    .css-treeview input{position:absolute;opacity:0}
    .css-treeview{font:normal 11px "Segoe UI",Arial,Sans-serif;-moz-user-select:none;-webkit-user-select:none;user-select:none}
    .css-treeview a{color:#00f;text-decoration:none}
    .css-treeview a:hover{text-decoration:underline}
    .css-treeview input ~ ul{display:none}
    .css-treeview label, .css-treeview label::before{cursor:pointer}
    .css-treeview input:disabled + label{cursor:default;opacity:.6}
    .css-treeview input:checked:not(:disabled) ~ ul{display:block}
    .css-treeview label, .css-treeview a, .css-treeview label::before{display:inline-block;height:16px;line-height:16px;vertical-align:middle}
    .css-treeview label, div {background-repeat:no-repeat;background-size: 16px 16px;}
    .css-treeview label{background-position:18px 0;}
    .css-treeview label::before{content:"";width:16px;margin:0 22px 0 0;vertical-align:middle;background:url("images/plus.png") no-repeat}
    .css-treeview div::before{content:"";width:16px;margin:0 22px 0 0;vertical-align:middle;background:url("images/plus.png") no-repeat}
    .css-treeview input:checked + label::before{background:url("images/minus.png") no-repeat}
    @media screen and (-webkit-min-device-pixel-ratio:0){.css-treeview{-webkit-animation:webkit-adjacent-element-selector-bugfix infinite 1s}
    @-webkit-keyframes webkit-adjacent-element-selector-bugfix{from{padding:0}to{padding:0}}}
  </style>
</head>
<body>
  <div class="css-treeview">]]
)

local printer = { lastIdent = -1}

----------------------------------------------------------------------------------
-- 1. Auxiliar Function
----------------------------------------------------------------------------------

function printer:write(ident, t, value, hasChild)
  local lastIdent = self.lastIdent

  if ident > lastIdent then
    file:write(string.rep("<ul>", ident - lastIdent))    
  elseif ident < lastIdent then
    file:write(string.rep("</ul>", lastIdent - ident))
  end
  self.lastIdent = ident  
  file:write('<li>')
  
  if hasChild then  
    local checked = t.collapse and "" or "checked"
    file:write(string.format('<input type="checkbox" %s /><label ', checked))
    
    if t.image then
      file:write(string.format('style="background-image: url(%s);"', t.image))
    end
    
    writeLine(file, string.format(">%s</label>", value))
  else
    file:write('<div')
    
    if t.image then
      file:write(string.format(' style="background-image: url(%s);"', t.image))
    end
    
    writeLine(file, string.format(">%s</div>",value))
  end
end

function printer:flush()
  writeLine(file, "</div>")
  writeLine(file, "</body>")
  file:close()
end

return printer