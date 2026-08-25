param(
  [string]$Org = "com.finora",
  [string]$ProjectName = "finora"
)

Set-Location (Join-Path $PSScriptRoot "..")
flutter create --platforms=ios --org $Org --project-name $ProjectName .
flutter pub get
