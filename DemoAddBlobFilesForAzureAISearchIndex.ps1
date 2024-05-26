$ConnectionString = '#EnterBlobConnectionString'
function Add-FileToBlobStorage {
    Param(
        [Parameter(Mandatory)]
        [ValidateScript({Test-Path $_ })]
        [string] $path,
        
        [Parameter(Mandatory)]
        [ValidateScript({$_ -match "https\:\/\/(.)*\.blob.core.windows.net\/(.)*\?(.)*"})]
        [string] $connectionString,
        
        [string] $foldername,
        
        [hashtable] $metadata
    )  

    # Upload single file
    $blobName = (Get-Item $path).Name
    if ($foldername) {
        $blobName = "$foldername/$blobName"
    }
    $blobUri = $connectionString.replace("?", "/$blobName`?")
    
    $HashArguments = @{
        uri = $blobUri
        method = "Put"
        InFile = $path
        headers = @{
            "x-ms-blob-type" = "BlockBlob"
        }
    }
    
    if ($metadata) {
        foreach ($key in $metadata.Keys) {
            $HashArguments.headers["x-ms-meta-$key"] = $metadata[$key]
        }
    }
    
    $Null=Invoke-RestMethod @HashArguments -RetryIntervalSec 5 -MaximumRetryCount 3
}

if (-Not (Test-Path C:\MSDocs)){New-Item -ItemType Directory -Path "C:\MSDocs"}
Set-Location "C:\MSDocs"
Git clone https://github.com/MicrosoftDocs/PowerShell-Docs

$PSDocs = Get-ChildItem "C:\MSDocs\PowerShell-Docs\reference\7.4" -recurse -filter *.md
foreach ($Doc in $PSDocs){
    $FolderName = $Doc.DirectoryName -replace 'C:\\MSDocs\\PowerShell-Docs\\reference\\7.4\\',''
    $URL = "https://learn.microsoft.com/en-us/powershell/module/$($FolderName -replace '\/','/')/" + $doc.basename + '?view=powershell-7.4'
    $metadata = @{url = $URL}
    Add-FileToBlobStorage -path $doc.fullname -connectionString $ConnectionString -foldername $foldername -metadata $metadata
}