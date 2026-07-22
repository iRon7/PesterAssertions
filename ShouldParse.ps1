using namespace System.Management.Automation.Language

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'False positive')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '', Justification = 'Required for custom test')]
param()

BeforeDiscovery {
    function Should-Parse([string] $ActualValue, [switch] $Negate, [string] $Because) {
        <#
        .SYNOPSIS
            Asserts if string contains valid PowerShell code
        .EXAMPLE
            'Write-Host "Hello World"' | Should -Parse

            Checks if 'Write-Host "Hello World"' is valid PowerShell code.
            This should pass.
        .EXAMPLE
            'Try { 1 + 1 }' | Should -Parse

            Checks if 'Try { 1 + 1 }' is valid PowerShell code.
            This will not pass (as a 'Try' block requires a 'Catch' block).
        #>

        $errors = $Null
        $null = [Parser]::ParseInput($ActualValue, [ref]$null, [ref]$errors)
        $succeeded = -not $errors -xor $Negate
        if (-not $succeeded) {
            $not = if ($Negate) { ' not' }
            $failureMessage = "Expected '$ActualValue'$Not to parse$(if($Because) { " because $Because"})."
        }

        return [PSCustomObject]@{
            Succeeded      = $succeeded
            FailureMessage = $failureMessage
        }
    }

    $ShouldParseSplat = @{
        Name               = 'Parse'
        InternalName       = 'Should-Parse'
        Test               = ${function:Should-Parse}
        SupportsArrayInput = $true
    }
    Add-ShouldOperator @ShouldParseSplat
}

Describe "Should-Parse" {

    Context "Passing" {

        It '[int]123 should parse' {
            '[int]123' | Should -Parse
        }

        It '[[int]]123 should not parse' {
            '[[int]]123' | Should -not -Parse
        }

        It 'Try without Catch should not parse' {
            'Try { 1 + 1 }' | Should -not -Parse
        }
    }

    Context "Failing" {

        It '[[int]]123 should parse should fail' {
            { '[[int]]123' | Should -Parse } | Should -Throw
        }

        It '[[int]]123 should not Parse should fail' {
            { '[int]123' | Should -not -Parse } | Should -Throw
        }
    }
}
