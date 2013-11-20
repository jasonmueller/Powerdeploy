function CreateRemoteSession {
    param(
        [string]$ComputerName,
        [System.Management.Automation.PSCredential]$Credential
    )

    Write-Verbose "Setting up session to $ComputerName for deployment..."

    $parameters = @{
        ComputerName = $ComputerName
        #SessionOption = New-PSSessionOption -NoMachineProfile
        #Authentication = 'Negotiate'
    }
       
    if ($Credential -ne $null) { $parameters.Credential = $Credential }
 
    try {
        Write-Verbose 'Trying connection using default authentication...'
        $session = New-PSSession @parameters
    }
    catch {
        if ($_.Exception.ErrorCode -ne 53) {
            # Error 53 (Network path not found) can occur if we are using
            # Kerberos authentication and the remote machine is not in the domain.
            $terminationException = $_.Exception
        }
    }

    if ($terminationException -eq $null -and $session -eq $null) {
        try {
            Write-Verbose 'Trying connection using Negotiate authentication...'
            $parameters.Authentication = 'Negotiate'
            $session = New-PSSession @parameters
        }
        catch {
            $terminationException = $_.Exception
        }
    }

    if ($terminationException -ne $null) {
        if ($terminationException.ErrorCode -eq 5) {
            throw New-Object ApplicationException("A session to $ComputerName could not be created.  If you are trying " +
                "to establish a connection to a remote computer, ensure that your current credentials have administrative " +
                "access to the remote computer or grant access using Set-PSSessionConfiguration.  Alternatively, you may " +
                "provide credentials that do have the required access.  If the remote computer is not in the same " +
                "domain as the local computer, you may need to add it to your Trusted Hosts.  If you are trying to establish a connection " +
                "to the local computer then a loopback session could not be created.  Ensure that the current user " +
                "is running elevated, with administrative privileges.", $terminationException)
        }
        elseif ($terminationException.ErrorCode -eq -2144108526) {
            throw New-Object ApplicationException("A remote session to $ComputerName could not be created.  Ensure that " +
                "PowerShell Remoting is enabled on the target computer.  See the Enable-PSRemoting cmdlet help for more " +
                "information.", $terminationException)
        }
        else {
            throw $terminationException
        }
    }    

    Write-Verbose "Remote session connected successfully."

    $session
}