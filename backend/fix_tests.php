<?php
$dir = new RecursiveDirectoryIterator(__DIR__ . '/tests/Feature');
$iterator = new RecursiveIteratorIterator($dir);

foreach ($iterator as $file) {
    if ($file->isFile() && $file->getExtension() === 'php') {
        $content = file_get_contents($file->getPathname());
        if (strpos($content, ", 'api'") !== false) {
            $newContent = str_replace(", 'api'", "", $content);
            file_put_contents($file->getPathname(), $newContent);
            echo "Fixed: " . $file->getFilename() . "\n";
        }
    }
}
echo "Done.\n";
