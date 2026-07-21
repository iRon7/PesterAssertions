using namespace System.Collections.Generic

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'False positive')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '', Justification = 'Required for custom test')]
param()

BeforeDiscovery {
    function Should-BeDistinct([string[]]$ActualValue, [switch]$Negate, [string]$Because) {
        $Duplicate = [HashSet[string]]::new([StringComparer]::InvariantCultureIgnoreCase)
        $Distinct = [HashSet[string]]::new([StringComparer]::InvariantCultureIgnoreCase)
        foreach ($Value in $ActualValue) {
            if (-not $distinct.Add($Value)) {
                $null = $Duplicate.Add($Value)
            }
        }

        $succeeded = [Bool]$Duplicate.get_Count() -eq $Negate
        if (-not $succeeded) {
            $not = if ($Negate) { ' not' }
            $failureMessage = switch ($Duplicate.Count) {
                0       { 'There are no duplicated values' } # Negated
                1       { "The value '$Duplicate' is not unique" }
                Default { "The value $($Duplicate.foreach{ '$_' } -Join ', ') are not unique" }
            }
        }

        return [PSCustomObject]@{
            Succeeded      = $succeeded
            FailureMessage = $failureMessage
        }
    }

    $ShouldBeDistinctSplat = @{
        Name               = 'BeDistinct'
        InternalName       = 'Should-BeDistinct'
        Test               = ${function:Should-BeDistinct}
        SupportsArrayInput = $true
    }
    Add-ShouldOperator @ShouldBeDistinctSplat
}

Describe "Should-BeDistinct" {

    Context "Passing" {

        It "'a', 'b', 'c'" {
            'a', 'b', 'c' | Should -BeDistinct
        }

        It "-not 'a', 'b', 'A'" {
           'a', 'b', 'A' | Should -not -BeDistinct
        }
    }

    Context "Failing" {

        It "{ 'a', 'b', 'c' | should -not -BeDistinct } should fail" {
            { 'a', 'b', 'c' | should -not -BeDistinct } | Should -ExpectedMessage 'There are no duplicated values'
        }

        It "{ 'a', 'b', 'A' | should -BeDistinct } should fail" {
            { 'a', 'b', 'A' | should -BeDistinct } | Should -ExpectedMessage "The value 'A' is not unique"
        }

        It "{ 'a', 'b', 'a', 'b' | should -BeDistinct } should fail" {
            { 'a', 'b', 'a', 'b' | should -BeDistinct } | Should -ExpectedMessage "The values 'a', 'b' are not unique"
        }
    }
}
