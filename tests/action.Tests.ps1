Describe "Update-TeamMember" {
    BeforeAll {
		$script:MemberName   = "test-user"
		$script:TeamName     = "test-team"
		$script:Role         = "member"
		$script:Token        = "fake-token"
		$script:Owner        = "test-owner"
		$script:MockApiUrl   = "http://127.0.0.1:3000"
        . "$PSScriptRoot/../action.ps1"
    }
	
    BeforeEach {
        $env:GITHUB_OUTPUT = New-TemporaryFile
        $env:MOCK_API = $script:MockApiUrl
    }
	
    AfterEach {
        if (Test-Path $env:GITHUB_OUTPUT) { Remove-Item $env:GITHUB_OUTPUT }
        Remove-Item Env:MOCK_API -ErrorAction SilentlyContinue
    }

	Context "Success Cases" {
	    It "unit: Update-TeamMember succeeds with HTTP 200 for member role" {
	        Mock Invoke-WebRequest {
	            [PSCustomObject]@{ StatusCode = 200; Content = '{"role":"member","state":"active"}' }
	        }
			
	        Update-TeamMember -MemberName $MemberName -TeamName $TeamName -Role "member" -Token $Token -Owner $Owner
			
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=success"
	    }
	
	    It "unit: Update-TeamMember succeeds with HTTP 200 for maintainer role" {
	        Mock Invoke-WebRequest {
	            [PSCustomObject]@{ StatusCode = 200; Content = '{"role":"maintainer","state":"active"}' }
	        }
			
	        Update-TeamMember -MemberName $MemberName -TeamName $TeamName -Role "maintainer" -Token $Token -Owner $Owner
			
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=success"
	    }	
	}

	Context "HTTP Failure Cases" {
	    It "unit: Update-TeamMember fails with HTTP 404 (team or user not found)" {
	        Mock Invoke-WebRequest {
	            [PSCustomObject]@{ StatusCode = 404; Content = '{"message":"Not Found"}' }
	        }
			
	        Update-TeamMember -MemberName $MemberName -TeamName $TeamName -Role "member" -Token $Token -Owner $Owner
			
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Error: Failed to update member test-user in team test-team with role member. HTTP Status: 404"
	    }
	}

	Context "Parameter Validation Failure Cases" {
	    It "unit: Update-TeamMember fails with invalid role" {
	        Update-TeamMember -MemberName $MemberName -TeamName $TeamName -Role "invalid-role" -Token $Token -Owner $Owner
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Error: Invalid role 'invalid-role'. Must be 'member' or 'maintainer'."
	    }
	
	    It "unit: Update-TeamMember fails with empty MemberName" {
	        Update-TeamMember -MemberName "" -TeamName $TeamName -Role $Role -Token $Token -Owner $Owner
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: MemberName, TeamName, Role, Token, and Owner must be provided."
	    }
	
	    It unit: Update-TeamMember "fails with empty TeamName" {
	        Update-TeamMember -MemberName $MemberName -TeamName "" -Role $Role -Token $Token -Owner $Owner
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: MemberName, TeamName, Role, Token, and Owner must be provided."
	    }
	
	    It "unit: Update-TeamMember fails with empty Role" {
	        Update-TeamMember -MemberName $MemberName -TeamName $TeamName -Role "" -Token $Token -Owner $Owner
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: MemberName, TeamName, Role, Token, and Owner must be provided."
	    }
	
	    It "unit: Update-TeamMember fails with empty Token" {
	        Update-TeamMember -MemberName $MemberName -TeamName $TeamName -Role $Role -Token "" -Owner $Owner
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: MemberName, TeamName, Role, Token, and Owner must be provided."
	    }
	
	    It "unit: Update-TeamMember fails with empty Owner" {
	        Update-TeamMember -MemberName $MemberName -TeamName $TeamName -Role $Role -Token $Token -Owner ""
	        $output = Get-Content $env:GITHUB_OUTPUT
	        $output | Should -Contain "result=failure"
	        $output | Should -Contain "error-message=Missing required parameters: MemberName, TeamName, Role, Token, and Owner must be provided."
	    }	
	}

	Context "Exception Failure Cases" {
		It "unit: Update-TeamMember fails with exception" {
			Mock Invoke-WebRequest { throw "API Error" }
	
			try {
				Update-TeamMember -MemberName $MemberName -TeamName $TeamName -Role $Role -Token $Token -Owner $Owner
			} catch {}
	
			$output = Get-Content $env:GITHUB_OUTPUT
			$output | Should -Contain "result=failure"
			$output | Where-Object { $_ -match "^error-message=Error: Failed to update $MemberName in team $TeamName with role $Role\. Exception:" } |
				Should -Not -BeNullOrEmpty
		}	
	}
}
