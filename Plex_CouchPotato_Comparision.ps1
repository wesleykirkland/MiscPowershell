#Check local powershell version
if (!($PSVersionTable.PSVersion.Major -ge '4')) {
    Write-Warning "You need to update powershell, please visit https://www.microsoft.com/en-us/download/details.aspx?id=40855 to download the latest version. Until then I will now exit" ;exit
}

#Change these variables, note this script does not support encrypted connections due to certificate mismatches
$PlexUsername = "admin"
$PlexPassword = "admin"
$CouchPotatoBaseURL = "https://192.168.1.40:5050/api/432b4acbaa0b416997364d3a2dad4162" #Find your API key by going to https://IPAddress:5050/docs"
$PlexURL = "http://192.138.1.50:32400" #Plex url, do not append after the port

#######################################################################################################################################################################################################
#Don't change anything below this line

#Find CouchPotato Movies
$CouchPotatoMovieList = (Invoke-RestMethod -Uri ($CouchPotatoBaseURL + "/movie.list")).movies.title

#Build string to login to Plex
$PlexAuth = '{0}:{1}' -f $PlexUsername,$PlexPassword
$url = "https://plex.tv/users/sign_in.xml"
$BB = [System.Text.Encoding]::UTF8.GetBytes($PlexAuth)
$EncodedPassword = [System.Convert]::ToBase64String($BB)
$headers = @{}
$headers.Add("Authorization","Basic $($EncodedPassword)") | out-null
$headers.Add("X-Plex-Client-Identifier","Script to Compare Media") | Out-Null
$headers.Add("X-Plex-Product","Custom Script API") | Out-Null
$headers.Add("X-Plex-Version","V1") | Out-Null
[xml]$res = Invoke-RestMethod -Headers:$headers -Method Post -Uri:$url
$token = $res.user.authenticationtoken

#Token
Write-Host "Here is your plex Auth Token for future reference"
$token

#Build query to query Plex Movies
#Build headers for query
$PlexLoginHeader = @{}
$PlexLoginHeader.Add("X-Plex-Token",$token) | Out-Null
$PlexMovieSections = Invoke-WebRequest -Headers:$PlexLoginHeader  -Uri ($PlexURL + "/library/sections ")
$PlexMovieSections = ([xml]$PlexMovieSections.Content).MediaContainer.Directory | Where-Object {($_.type -eq 'movie')}

#Build an array of the movies in Plex
$PlexMovieArray = @()

#Foreach Section that is a movie
foreach ($Section in $PlexMovieSections) {
    $Key = $Section.Key
    $PlexMovieArray += (Invoke-RestMethod -Uri ($PlexURL + "/library/sections/$Key/all") -Headers $PlexLoginHeader).mediacontainer.video.title
}

#Compare movies in CouchPototo vs Plex
$ComparisionofPlexVSCouchPotato = Compare-Object -ReferenceObject $CouchPotatoMovieList -DifferenceObject $PlexMovieArray -IncludeEqual

#Media File Location
$FileLocation = ($env:TEMP + "\Media_Compare.csv")
$ComparisionofPlexVSCouchPotato | Export-Csv $FileLocation -NoTypeInformation

Write-Host "The csv export is stored at $FileLocation"
Write-Host "=> Means the file exists in Plex but not in CouchPotato"
Write-Host "<= Means the file exists in CouchPotato but not into Plex"
Write-Host "== Means the file exists in both places"

Invoke-Item $FileLocation