param (
    [Parameter(Mandatory = $true)]
    [string]
    $codeDxUrl,
    
    [Parameter(Mandatory = $true)]
    [int] $projectId,
    
    [Parameter(Mandatory = $true)]
    [string]$apiKey,
    
    [Parameter(Mandatory = $true)]
    [string]$filePaths
)

Write-Host -Verbose "Code Dx URL: $codeDxUrl"
Write-Host -Verbose "Project ID: $projectId"
Write-Host -Verbose "API key: $apiKey"
Write-Host -Verbose "Paths: $filePaths"

# make sure to include the Http assembly to get access to the HttpClient
Add-Type -AssemblyName System.Net.Http

$client = New-Object System.Net.Http.Httpclient

try {
    Write-Host -Verbose "Source/binaries filenames: $fileName"

    #build the full analysis url
    $fullUrl = "$codeDxUrl/api/projects/$projectId/analysis"

    Write-Host -Verbose "Full URL: $fullUrl"

    $content = New-Object System.Net.Http.MultipartFormDataContent
    $fileCount = 0;
	
    $delimiters = @("`r`n", "`r", "`n")
    $option = [System.StringSplitOptions]::RemoveEmptyEntries

    ForEach ($path in $($filePaths.Split($delimiters, $option))) {
        $fileCount = $fileCount + 1; 
	   
        Write-Host -Verbose "Processing $path as file$fileCount..."
		
        $fileName = [System.IO.Path]::GetFileName($path)

        #build the message content
        Write-Host -Verbose "Reading contents of $fileName..."
        [byte[]]$sourceBytes = [System.IO.File]::ReadAllBytes($path)
        $l = $sourceBytes.Length
        Write-Host -Verbose "Content size: $l bytes"

        Write-Host -Verbose "Building HTTP content..."
        $byteContent = New-Object System.Net.Http.ByteArrayContent($sourceBytes, 0, $l)
        $content.Add($byteContent, "file$count", $fileName);
    }
	
    $postMethod = [System.Net.Http.HttpMethod]::Post

    Write-Host -Verbose "Building request message..."
    $message = New-Object System.Net.Http.HttpRequestMessage($postMethod, $fullUrl)
    $message.Headers.Clear()
    $message.Headers.Add("API-Key", $apiKey)
    $message.Content = $content

    # Get the web content.
    Write-Host -Verbose "Sending source to Code Dx..."
    $task = $client.SendAsync($message)

    # waiting so the task will throw.
    $task.Wait()

    $response = $task.Result;

    if ($response -ne $null) {
        Write-Host -Verbose "Reading response..."
        $responseContent = $response.Content.ReadAsStringAsync().Result
   
        Write-Host -Verbose "Response: $responseContent"
    }
    else {
        Write-Host -Verbose "Response is null."
    }
}   
finally {
    if ($client -ne $null) {
        $client.Dispose()
    }
}