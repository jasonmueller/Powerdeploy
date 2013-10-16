param(
    $outDirectory
)

$tempPath = Join-Path $env:Temp ([Guid]::NewGuid().ToString())
hg id -n | set id
if ($id.endswith('+')) {
    throw 'Cannot deploy with local changes.'
}

hg archive -r $id $tempPath

$source = Join-Path $tempPath Source
$dest = Join-Path $outDirectory $id

cp $source $dest -rec