param(
  [string]$BeforeFile,
  [string]$AfterFile,
  [string]$OutFile
)

$before = Get-Content $BeforeFile -Raw | ConvertFrom-Json
$after  = Get-Content $AfterFile  -Raw | ConvertFrom-Json

# הפוך למילונים לפי path
$b = @{}
foreach ($x in $before) { $b[$x.path] = $x }

$a = @{}
foreach ($x in $after) { $a[$x.path] = $x }

$created = @()
$deleted = @()
$modified = @()

foreach ($p in $a.Keys) {
  if (-not $b.ContainsKey($p)) {
    $created += $a[$p]
  }
}

foreach ($p in $b.Keys) {
  if (-not $a.ContainsKey($p)) {
    $deleted += $b[$p]
  }
}

foreach ($p in $a.Keys) {
  if ($b.ContainsKey($p)) {
    $old = $b[$p]
    $new = $a[$p]
    if (($old.sha256 -ne $new.sha256) -or ($old.size -ne $new.size)) {
      $modified += [PSCustomObject]@{ before = $old; after = $new }
    }
  }
}

$result = [PSCustomObject]@{
  created  = $created
  deleted  = $deleted
  modified = $modified
}

$result | ConvertTo-Json -Depth 6 | Out-File -Encoding UTF8 $OutFile
