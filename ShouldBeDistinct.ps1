using namespace System.Collections.Generic

[Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'False positive')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSUseApprovedVerbs', '', Justification = 'Required for custom test')]
param()

BeforeDiscovery {

    #https://stackoverflow.com/a/79983730/1701026
    class EqualityComparerInvariantCultureIgnoreCase : IEqualityComparer[object] {
        [bool] Equals([object] $o1, [object] $o2) {
            return [StringComparer]::InvariantCultureIgnoreCase.Equals($o1, $o2)
        }

        [int] GetHashCode([object] $o) {
            return [StringComparer]::InvariantCultureIgnoreCase.GetHashCode($o)
        }
    }
    function Should-BeDistinct($ActualValue, [switch]$Negate, [string]$Because) {
        $Duplicate = $null
        $Distinct = [HashSet[object]]::new([EqualityComparerInvariantCultureIgnoreCase]::new())
        foreach ($Value in $ActualValue) {
            if (-not $distinct.Add($Value)) {
                if ($null -eq $Duplicate) {
                    $Duplicate = [HashSet[object]]::new([EqualityComparerInvariantCultureIgnoreCase]::new())
                }
                $null = $Duplicate.Add($Value)
            }
        }

        $succeeded = $null -eq $Duplicate -xor $Negate
        if (-not $succeeded) {
            $not = if ($Negate) { ' not' }
            $failureMessage = switch ($Duplicate.Count) {
                0       { 'There are no duplicated values' } # Negated
                1       { "The value '$Duplicate' is not unique" }
                Default { "The values $($Duplicate.foreach{ '''' + $_ + '''' } -Join ', ') are not unique" }
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

        It "Strings" {
            'a', 'b', 'c' | Should -BeDistinct
        }

        It 'Integers' {
            1..5 | Should -BeDistinct
        }

        It 'Types' {
            [Int], [Long], [String] | Should -BeDistinct
        }

        It "Indistinct strings" {
           'a', 'b', 'A' | Should -not -BeDistinct
        }

        It "Indistinct integers" {
           1, 2, 3, 2, 1 | Should -not -BeDistinct
        }

        It 'Indistinct types' {
            [Int], [Long], [String], [Long] | Should -not -BeDistinct
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
