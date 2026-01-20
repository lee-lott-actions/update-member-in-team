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
        Write-Output "Error: Invalid role '$Role'. Must be 'member' or 'maintainer'."
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Invalid role '$Role'. Must be 'member' or 'maintainer'."
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        return
    }

    Write-Host "Attempting to add member '$MemberName' to team '$TeamName' in organization '$Owner' with role '$Role'"

    # Use MOCK_API if set, otherwise default to GitHub API
    $apiBaseUrl = $env:MOCK_API
    if (-not $apiBaseUrl) { $apiBaseUrl = "https://api.github.com" }
    $uri = "$apiBaseUrl/orgs/$Owner/teams/$TeamName/memberships/$MemberName"

    $headers = @{
        Authorization        = "Bearer $Token"
        Accept               = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
        "User-Agent"         = "pwsh-action"
        "Content-Type"       = "application/json"
    }

    $jsonBody = @{ role = $Role } | ConvertTo-Json

    try {
        Write-Host "Sending request to $uri"
        $response = Invoke-WebRequest -Uri $uri -Headers $headers -Method Put -Body $jsonBody

        if ($response.StatusCode -eq 200) {
            Write-Host "Successfully updated $MemberName in team $TeamName with role $Role"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=success"
        } else {
            Write-Host "Error: Failed to update $MemberName in team $TeamName with role $Role. HTTP Status: $($response.StatusCode)"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Failed to update member $MemberName in team $TeamName with role $Role. HTTP Status: $($response.StatusCode)"
            Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
        }
    } catch {
        $httpStatus = $_.Exception.Response.StatusCode.value__
        Write-Host "Error: Failed to update $MemberName in team $TeamName with role $Role. HTTP Status: $httpStatus"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "error-message=Failed to update member $MemberName in team $TeamName with role $Role. HTTP Status: $httpStatus"
        Add-Content -Path $env:GITHUB_OUTPUT -Value "result=failure"
    }
}