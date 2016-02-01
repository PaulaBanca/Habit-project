local M={}
sqlite3constants=M

local tostring=tostring

setfenv(1,M)

local constants={}
constants[0]="OK"
constants[1]="ERROR"
constants[2]="INTERNAL"
constants[3]="PERM"
constants[4]="ABORT"
constants[5]="BUSY"
constants[6]="LOCKED"
constants[7]="NOMEM"
constants[8]="READONLY"
constants[9]="INTERRUPT"
constants[10]="IOERR"
constants[11]="CORRUPT"
constants[12]="NOTFOUND"
constants[13]="FULL"
constants[14]="CANTOPEN"
constants[15]="PROTOCOL"
constants[16]="EMPTY"
constants[17]="SCHEMA"
constants[18]="TOOBIG"
constants[19]="CONSTRAINT"
constants[20]="MISMATCH"
constants[21]="MISUSE"
constants[22]="NOLFS"
constants[24]="FORMAT"
constants[25]="RANGE"
constants[26]="NOTADB"
constants[100]="ROW"
constants[101]="DONE"

function getLookupCode(code)
  return tostring(constants[code])
end

return M