function get_auth_token() {
    $url_gettoken = "https://auth.na1.data.vmwservices.com/oauth/token?grant_type=client_credentials"
    $client_id = "power_bi_reporting@bf68fa27-e8de-4669-b7fb-79827fb6a673.data.vmwservices.com"
    $client_secret = "6D98A039C3C1D3A0CE2B6B8954D0431872791676D7F06C999AF4D0DEBBD85637"
    $encoded = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("power_bi_reporting@bf68fa27-e8de-4669-b7fb-79827fb6a673.data.vmwservices.com:6D98A039C3C1D3A0CE2B6B8954D0431872791676D7F06C999AF4D0DEBBD85637"))

    $headers_gettoken = @{ Authorization = "Basic $encoded"}
    $gettoken = Invoke-RestMethod -Uri $url_gettoken -Method Post -Headers $headers_gettoken
    return $gettoken.access_token
}

function get_downloads() {
    param($token)
    $report_id = "f4baf99c-d794-4eab-8a07-4a0414a61370"

    $headers_getreportloc = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    $body_getreportloc = @{
        "offset" = "0"
        "page_size" = "10"
    } | ConvertTo-Json

    $url_getreportloc = "https://api.na1.data.vmwservices.com/v1/reports/" + $report_id + "/downloads/search"
    $getreportloc = Invoke-RestMethod -Uri $url_getreportloc -Method Post -Headers $headers_getreportloc -Body $body_getreportloc
    $getreportloc_data = $getreportloc.PSObject.Properties.Value | % {$_.results}

    return $getreportloc_data
}

Function verify_download_id() {
    param($download_obj)

    $status = $download_obj.status

    if ($status -eq "COMPLETED") {
        return $true
    } else {
        return $false
    }
}

function download_report_csv() {
    param($download_id,$token)

    $headers_download_report = @{
        "Authorization" = "Bearer $token"
        "Content-Type" = "application/json"
    }
    $body_download_report = @{
        "offset" = "0"
        "page_size" = "10"
    } | ConvertTo-Json

    $url_download_report = "https://api.na1.data.vmwservices.com/v2/reports/tracking/" + $download_id + "/download"
    $download_report = Invoke-RestMethod -Uri $url_download_report -Method Get -Headers $headers_download_report

    return $download_report
}

$token = ""
$token = get_auth_token
$downloads_arr = get_downloads -token $token

$download_id = ""
for ($i = 0; $i -lt $downloads_arr.Length; $i++) {
    $flag = verify_download_id -download_obj $downloads_arr[$i]
    if ($flag -eq $true) {
        $download_id = $downloads_arr[$i].id
        break
    }
}

$report = download_report_csv -download_id $download_id -token $token
Write-Output $report