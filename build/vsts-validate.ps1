# Run internal pester tests
Import-Module "$PSScriptRoot\..\cScom\cScom.psd1" -Force
& "$PSScriptRoot\..\tests\pester.ps1"