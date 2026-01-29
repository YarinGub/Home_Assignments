param(
  [string[]]$Paths,
  [string]$OutFile
)

$items = foreach ($p in $Paths) {
  if (Test-Path $p) {
    Get-ChildItem -Path $p -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
      $hash = ""
      try {
        $hash = (Get-FileHash $_.FullName -Algorithm SHA256 -ErrorAction Stop).Hash
      } catch {
        $hash = ""
      }
      [PSCustomObject]@{
        path   = $_.FullName
        size   = $_.Length
        mtime  = $_.LastWriteTimeUtc.ToString("o")
        sha256 = $hash
      }
    }
  }
}

$items | ConvertTo-Json -Depth 3 | Out-File -Encoding UTF8 $OutFile
