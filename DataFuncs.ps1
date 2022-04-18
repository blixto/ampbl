using namespace System.Collections

function Get-IndexOfClosestRD
{
    param
    (
        [string]$Line,
        [int]$CurrentIndex,
        [int]$Level,
        [char]$LD = "(",
        [char]$MD = ";",
        [char]$RD = ")"
    )

    $lvl = 0
    for ($i = 0; $i -lt $Line.Length; $i++)
    {
        $c = $Line[$i]
        if ($c -eq $LD)
        {
            $lvl++
        }
        elseif ($c -eq $RD)
        {
            if ($lvl -eq $Level)
            {
                if ($i -ge $CurrentIndex)
                {
                    return $i
                }
            }

            $lvl--
        }
    }

    return -1
}

Set-Alias closest Get-IndexOfClosestRD

function Split-String
{
    param
    (
        [string]$Line,
        [switch]$Recurse,
        [char]$LD = "(",
        [char]$MD = ";",
        [char]$RD = ")"
    )

    $array = [ArrayList]::new()
    $lvl = $idx = 0
    $acc = ""; $quote = $false; $esc = $false
    for ($i = 0; $i -lt $Line.Length; $i++)
    {
        $c = $Line[$i]
        if ($c -eq $LD -and -not $quote)
        {
            $lvl++
            if ($lvl -gt 1)
            {
                $st = $i
                $end = closest $Line $i 2
                $len = $end - $st + 1
                if ($Recurse)
                {
                    $idx = $array.Add((Split-String $Line.Substring($st, $len) -Recurse))
                }
                else
                {
                    $idx = $array.Add($Line.Substring($st, $len))
                }

                $i = $end + 1
            }
        }
        elseif ($c -eq $RD -and -not $quote)
        {
            $lvl--
            $idx = $array.Add($acc)
            return $array
        }
        elseif ($c -eq $MD -and -not $quote)
        {
            $idx = $array.Add($acc)
            $acc = ""
        }
        else
        {
            if ($c -eq '\')
            {
                if ($esc)
                {
                    $esc = $false
                }
                else
                {
                    $esc = $true
                }

                continue
            }

            if ($c -eq '"' -and -not $quote)
            {
                $quote = $true
                if (-not $esc)
                {
                    $c = ""
                }
            }
            elseif ($c -eq '"')
            {
                $quote = $false
                if (-not $esc)
                {
                    $c = ""
                }
            }
            
            $acc += "$c"
            $esc = $false
        }
    }

    return $array
}

Set-Alias splits Split-String

$stack = [ArrayList]::new()

function Start-Parsing
{
    param
    (
        [string[]]$Tokens
    )

    switch -Regex ($Tokens[0])
    {
        '\('
        {
            return (Start-Parsing (splits $Tokens))
        }

        '^!$'
        {
            for ($i = 1; $i -lt $Tokens.Length; $i++)
            {
                Start-Parsing $Tokens[$i]
            }
        }

        '%'
        {
            [ref]$val = 0
            if ([double]::TryParse($Tokens[0].Substring(1), $val))
            {
                return $val.Value
            }
            else
            {
                return $Tokens[0].Substring(1)
            }
        }

        '^->$'
        {
            if ((Start-Parsing $Tokens[1]) -eq "~~~")
            {
                $stack.Clear()
            }
            else
            {
                for ($i = 1; $i -lt $Tokens.Length; $i++)
                {
                    $stack.Add((Start-Parsing $Tokens[$i])) | Out-Null
                }
            }
        }

        '^<-$'
        {
            [ref]$i = 0
            if ([int]::TryParse((Start-Parsing $Tokens[1]), $i))
            {
                return $stack[$i.Value]
            }
            else
            {
                return $null
            }
        }

        '\?'
        {
            $c = Start-Parsing $Tokens[1]
            $t = Start-Parsing $Tokens[2]
            $f = Start-Parsing $Tokens[3]

            if ($c -eq "T")
            {
                return $t
            }
            else
            {
                return $f
            }
        }

        '^~$'
        {
            $val = Start-Parsing $Tokens[1]
            if ($val -eq "T")
            {
                return "F"
            }

            return "T"
        }

        '^==$'
        {
            $lval = Start-Parsing $Tokens[1]
            $rval = Start-Parsing $Tokens[2]

            if ($lval -eq $rval)
            {
                return "T"
            }
            else
            {
                return "F"
            }
        }

        '^!=$'
        {
            $lval = Start-Parsing $Tokens[1]
            $rval = Start-Parsing $Tokens[2]

            if ($lval -ne $rval)
            {
                return "T"
            }
            else
            {
                return "F"
            }
        }

        '^>=$'
        {
            $lval = Start-Parsing $Tokens[1]
            $rval = Start-Parsing $Tokens[2]

            if ($lval -ge $rval)
            {
                return "T"
            }
            else
            {
                return "F"
            }
        }

        '^>$'
        {
            $lval = Start-Parsing $Tokens[1]
            $rval = Start-Parsing $Tokens[2]

            if ($lval -gt $rval)
            {
                return "T"
            }
            else
            {
                return "F"
            }
        }

        '^<=$'
        {
            $lval = Start-Parsing $Tokens[1]
            $rval = Start-Parsing $Tokens[2]

            if ($lval -le $rval)
            {
                return "T"
            }
            else
            {
                return "F"
            }
        }

        '^<$'
        {
            $lval = Start-Parsing $Tokens[1]
            $rval = Start-Parsing $Tokens[2]

            if ($lval -lt $rval)
            {
                return "T"
            }
            else
            {
                return "F"
            }
        }

        '^\+$'
        {
            $acc = 0
            for ($i = 1; $i -lt $Tokens.Length; $i++)
            {
                $acc += (Start-Parsing $Tokens[$i])
            }

            return $acc
        }

        '^-$'
        {
            $acc = Start-Parsing $Tokens[1]
            for ($i = 2; $i -lt $Tokens.Length; $i++)
            {
                $acc -= (Start-Parsing $Tokens[$i])
            }

            return $acc
        }

        '^\*$'
        {
            $acc = 1
            for ($i = 1; $i -lt $Tokens.Length; $i++)
            {
                $acc *= (Start-Parsing $Tokens[$i])
            }

            return $acc
        }

        '^/{1}$'
        {
            $lval = Start-Parsing $Tokens[1]
            $rval = Start-Parsing $Tokens[2]

            if ($rval -ne 0)
            {
                return $lval / $rval
            }
            else
            {
                return 0
            }
        }

        '^\^$'
        {
            $base = Start-Parsing $Tokens[1]
            $exp = Start-Parsing $Tokens[2]
            return [Math]::Pow($base, $exp)
        }

        '^//$'
        {
            $lval = Start-Parsing $Tokens[1]
            $rval = Start-Parsing $Tokens[2]

            if ($rval -ne 0)
            {
                return $lval % $rval
            }
            else
            {
                return 0
            }
        }

        '^&$'
        {
            for ($i = 1; $i -lt $Tokens.Length; $i++)
            {
                if ((Start-Parsing $Tokens[$i]) -eq "F")
                {
                    return "F"
                }
            }

            return "T"
        }

        '^@$'
        {
            for ($i = 1; $i -lt $Tokens.Length; $i++)
            {
                if ((Start-Parsing $Tokens[$i]) -eq "T")
                {
                    return "T"
                }
            }

            return "F"
        }

        '^[0-9]{3}$'
        {
            return __get_rec_data $Tokens[0]
        }

        '^[0-9]{5}$'
        {
            return __get_rec_data $Tokens[0] -cross
        }

        '§'
        {
            for ($i = 1; $i -lt $Tokens.Length; $i++)
            {
                $r = (Start-Parsing $Tokens[$i])
                $m = ""
                switch -Regex ($r)
                {
                    '^T$|^F$'
                    {
                        if ($r -eq "T")
                        {
                            $m = "True"
                        }
                        else
                        {
                            $m = "False"
                        }
                    }

                    default
                    {
                        $m = $r
                    }
                }

                Write-Host $m
            }
        }

        default
        {
            switch -Regex ($Tokens[0])
            {
                '[0-9]{1,2}|[0-9]{4}|[0-9]{6,}'
                {
                    Write-Host "ERROR. Number" "`"$($Tokens[0])`"" "malformed."
                }

                '^[a-zA-Z0-9]+$'
                {
                    Write-Host "ERROR. Unrecognized command" "`"$($Tokens[0])`""
                }

                default
                {
                    Write-Host "ERROR. Internal Error"
                }
            }
        }
    }
}

Set-Alias parse Start-Parsing

function Format-OutFile
{
    param()
    return;
}

Set-Alias format Format-OutFile
#------------------------------------------------------------------------------
function __aux_and
{
    param([bool[]]$conds)

    foreach ($cond in $conds)
    {
        if (-not $cond)
        {
            return $false
        }
    }

    return $true
}

function __aux_or
{
    param([bool[]]$conds)

    foreach ($cond in $conds)
    {
        if ($cond)
        {
            return $true
        }
    }

    return $false
}

function __get_rec_data
{
    param
    (
        [string]$refseq,
        [switch]$cross
    )

    $file = @("00|HELLO|WORLD|HI|THERE", "10|HELLO|WORLD|HI|THERE")
    $criteria = @("00|(00;(001;001);(002;002))")
    $r = ($cross) ? $refseq.Substring(0, 2) : ""
    if ($r -eq "")
    {
        [ref]$f = 0
        if ([int]::TryParse($refseq, $f))
        {
            return ($file[0] -split "\|")[$f.Value]
        }
        else
        {
            return ""
        }
    }
    else
    {
        foreach ($line in $file)
        {
            if ($line -match "^$r\|.+$")
            {
                [ref]$f = 0
                if ([int]::TryParse($refseq.Substring(2), $f))
                {
                    return ($line -split "\|")[$f.Value]
                }
                else
                {
                    return ""
                }
            }
        }
    }
}