$content = Get-Content -Path 'c:\Users\angel\OneDrive\Escritorio\Proyectos\myapp\lib\screens\add_video_screen.dart' -Raw
$content = $content -replace 'Navigator\.pop\(currentContext\)', 'Navigator.pop(context)'
$content = $content -replace 'final BuildContext\\? currentContext = mounted \\? context : null;', ''
$content = $content -replace 'if \(currentContext != null\) \{[\r\n\s]+ScaffoldMessenger\.of\(currentContext\)', 'if (mounted) {
        ScaffoldMessenger.of(context)'
Set-Content -Path 'c:\Users\angel\OneDrive\Escritorio\Proyectos\myapp\lib\screens\add_video_screen.dart' -Value $content

$content = Get-Content -Path 'c:\Users\angel\OneDrive\Escritorio\Proyectos\myapp\lib\screens\video_detail_screen.dart' -Raw
$content = $content -replace 'ScaffoldMessenger\.of\(context\)\.showSnackBar', 'if (mounted) { ScaffoldMessenger.of(context).showSnackBar'
$content = $content -replace '(showSnackBar\([^)]+\));\r?\n\s+}', '\; }'
Set-Content -Path 'c:\Users\angel\OneDrive\Escritorio\Proyectos\myapp\lib\screens\video_detail_screen.dart' -Value $content
