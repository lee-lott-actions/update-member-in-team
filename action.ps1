function Update-TeamMember {
    param(
        [string]$MemberName,
        [string]$TeamName,
        [string]$Role,
        [string]$Token,
        [string]$Owner
    )

    # Validate required parameters
    if ([string]::IsNullOrEmpty($MemberName) -or
        [string]::IsNullOrEmpty($TeamName) -or
        [string]::IsNullOrEmpty($Role) -or
        [string]::IsNullOrEmpty($Token) -or
        [string]::IsNullOrEmpty($Owner)) {
        Write-Output "Error: Missing required parameters"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Missing required parameters: MemberName, TeamName, Role, Token, and Owner must be provided."
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        return
    }

    # Convert Role to lowercase for API compatibility
    $Role = $Role.ToLower()

    # Validate role
    if ($Role -ne "member" -and $Role -ne "maintainer") {
		$errorMsg = "Error: Invalid role '$Role'. Must be 'member' or 'maintainer'."        
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
        Write-Output $errorMsg
        return
    }    

    # Use MOCK_API if set, otherwise default to GitHub API
    $apiBaseUrl = $env:MOCK_API
    if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }
    $uri = "$apiBaseUrl/orgs/$Owner/teams/$TeamName/memberships/$MemberName"

    $headers = @{
        Authorization = "Bearer $Token"
        Accept = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2026-03-10"
        "Content-Type" = "application/json"
    }

    $body = @{ role = $Role } | ConvertTo-Json

    try {
        Write-Host "Attempting to add member '$MemberName' to team '$TeamName' in organization '$Owner' with role '$Role'"
        $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method Put -Body $body -SkipHttpErrorCheck

        if ($response.StatusCode -eq 200) {
            Write-Host "Successfully updated $MemberName in team $TeamName with role $Role"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
        } else {
			$errorMsg ="Error: Failed to update $MemberName in team $TeamName with role $Role. HTTP Status: $($response.StatusCode)" 
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
			Write-Host $errorMsg
        }
    } catch {
		$errorMsg = "Error: Failed to update $MemberName in team $TeamName with role $Role. Exception: $($_.Exception.Message)"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
		Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=$errorMsg"
		Write-Host $errorMsg
    }
}
