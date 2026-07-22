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

    function Should-BeUnique($ActualValue, [string]$ExpectedValue, [switch]$Negate, [string]$Because) {
        if (-not $UniqueLists.Contains($ExpectedValue)) {
            $UniqueLists[$ExpectedValue] = [HashSet[object]]::new([EqualityComparerInvariantCultureIgnoreCase]::new())
        }
        $Duplicate = $null
        foreach ($Value in $ActualValue) {
            if (-not $UniqueLists[$ExpectedValue].Add($Value)) {
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
                0       { "None of the values are in '$ExpectedValue'" } # Negated
                1       { "The value '$Duplicate' is not a unique $ExpectedValue item" }
                Default { "The value $($Duplicate.foreach{ '''' + $_ + '''' } -Join ', ') are not unique $ExpectedValue items" }
            }
        }

        return [PSCustomObject]@{
            Succeeded      = $succeeded
            FailureMessage = $failureMessage
        }
    }

    $ShouldBeUniqueSplat = @{
        Name               = 'BeUnique'
        InternalName       = 'Should-BeUnique'
        Test               = ${function:Should-BeUnique}
        SupportsArrayInput = $true
    }
    Add-ShouldOperator @ShouldBeUniqueSplat
}

BeforeAll {
    $UniqueLists = @{}

    $UserList = ConvertFrom-Json '[
        {
            "id": "User001",
            "name": "John Doe",
            "email": "jdoe@fabrikam.com"
        },
        {
            "id": "User002",
            "name": "Bill Gates",
            "email": "bgates@fabrikam.com"
        },
        {
            "id": "User003",
            "name": "Jane Doe",
            "email": "jdoe@fabrikam.com"
        }
    ]'
}

Describe "Should-BeUnique" {

    Context "Passing" {

        It "Id and Name" -ForEach $UserList {
            $id   | Should -BeUnique UserId   # UserId is a variable name for a pool of userIds that are unique
            $name | Should -BeUnique UserName # UserName is a variable name for a pool of userNames that are unique
        }
    }

    Context "Failing" {

        It "Email"  {
            $UserList.email[0] | Should -BeUnique Email
            $UserList.email[1] | Should -BeUnique Email
            { $UserList.email[2] | Should -BeUnique Email } | Should -ExpectedMessage "The value 'jdoe@fabrikam.com' is not a unique Email item"
        }
    }
}
