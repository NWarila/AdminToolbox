Function Convert-SubnetToCIDR {
        [CmdletBinding(ConfirmImpact = 'None')]
        param(
            [Parameter(Mandatory)]
            [ValidateNotNullOrEmpty()]
            [String]$subnetmask
        )
        If ($Subnets -notmatch 
            '^(((255\.){3}(255|254|252|248|240|224|192|128|0+))|' + 
            '((255\.){2}(255|254|252|248|240|224|192|128|0+)\.0)|' + '
            ((255\.)(255|254|252|248|240|224|192|128|0+)(\.0+){2})|' + 
            '((255|254|252|248|240|224|192|128|0+)(\.0+){3}))$') {
            Throw 'Invalid Subnet mask'
        }

        New-Variable -Name:'CIDR' -Value:([Int]0)
        $SubnetMask.split('.') | ForEach-Object {
            $CIDR += @{255 = 8; 254 = 7; 252 = 6; 248 = 5; 
                240 = 4; 224 = 3; 192 = 2; 128 = 1 
            }[[Int]$_]
        }
        Return $CIDR
    }
