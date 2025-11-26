package com.libpostal;

import java.io.*;
import java.nio.file.*;

/**
 * Handles loading native libraries from JAR resources.
 * Extracts platform-specific libraries to temp directory and loads them.
 */
public class NativeLoader {
    
    private static boolean loaded = false;
    private static String tempDir = null;
    
    /**
     * Load native libraries from JAR or system path.
     * Automatically detects platform and loads appropriate libraries.
     */
    public static synchronized void loadLibraries() {
        if (loaded) {
            return;
        }
        
        String osName = System.getProperty("os.name").toLowerCase();
        String osArch = System.getProperty("os.arch").toLowerCase();
        
        // Determine platform
        String platform = detectPlatform(osName, osArch);
        if (platform == null) {
            throw new UnsatisfiedLinkError("Unsupported platform: " + osName + " " + osArch);
        }
        
        try {
            // Try to load from JAR first
            loadFromJar(platform);
            loaded = true;
        } catch (Exception e) {
            // Fall back to system library path
            try {
                System.loadLibrary("postal");
                System.loadLibrary("postal_jni");
                loaded = true;
            } catch (UnsatisfiedLinkError sysError) {
                throw new UnsatisfiedLinkError(
                    "Failed to load native libraries from JAR and system path.\n" +
                    "JAR error: " + e.getMessage() + "\n" +
                    "System error: " + sysError.getMessage()
                );
            }
        }
    }
    
    /**
     * Detect platform identifier.
     */
    private static String detectPlatform(String osName, String osArch) {
        String os = null;
        String arch = null;
        
        // Determine OS
        if (osName.contains("win")) {
            os = "windows";
        } else if (osName.contains("mac") || osName.contains("darwin")) {
            os = "macos";
        } else if (osName.contains("linux")) {
            os = "linux";
        }
        
        // Determine architecture
        if (osArch.contains("amd64") || osArch.contains("x86_64")) {
            arch = "x86_64";
        } else if (osArch.contains("aarch64") || osArch.contains("arm64")) {
            arch = "aarch64";
        } else if (osArch.contains("x86") || osArch.contains("i386")) {
            arch = "x86";
        }
        
        if (os == null || arch == null) {
            return null;
        }
        
        return os + "-" + arch;
    }
    
    /**
     * Load libraries from JAR resources.
     */
    private static void loadFromJar(String platform) throws IOException {
        // Create temp directory for extracted libraries
        if (tempDir == null) {
            Path temp = Files.createTempDirectory("libpostal-native-");
            tempDir = temp.toAbsolutePath().toString();
            
            // Delete on exit
            temp.toFile().deleteOnExit();
        }
        
        // Determine library names based on platform
        String libPostalName;
        String libPostalJniName;
        
        if (platform.startsWith("windows")) {
            libPostalName = "postal.dll";
            libPostalJniName = "postal_jni.dll";
        } else if (platform.startsWith("macos")) {
            libPostalName = "libpostal.dylib";
            libPostalJniName = "libpostal_jni.dylib";
        } else {
            libPostalName = "libpostal.so";
            libPostalJniName = "libpostal_jni.so";
        }
        
        // Extract and load libpostal first
        String libPostalPath = extractLibrary(platform, libPostalName);
        System.load(libPostalPath);
        
        // Extract and load libpostal_jni
        String libPostalJniPath = extractLibrary(platform, libPostalJniName);
        System.load(libPostalJniPath);
    }
    
    /**
     * Extract library from JAR to temp directory.
     */
    private static String extractLibrary(String platform, String libraryName) throws IOException {
        String resourcePath = "/native/" + platform + "/" + libraryName;
        
        try (InputStream in = NativeLoader.class.getResourceAsStream(resourcePath)) {
            if (in == null) {
                throw new FileNotFoundException("Library not found in JAR: " + resourcePath);
            }
            
            File outputFile = new File(tempDir, libraryName);
            outputFile.deleteOnExit();
            
            try (FileOutputStream out = new FileOutputStream(outputFile)) {
                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = in.read(buffer)) != -1) {
                    out.write(buffer, 0, bytesRead);
                }
            }
            
            // Make executable (Unix-like systems)
            outputFile.setExecutable(true);
            outputFile.setReadable(true);
            
            return outputFile.getAbsolutePath();
        }
    }
    
    /**
     * Get the temporary directory where libraries are extracted.
     */
    public static String getTempDir() {
        return tempDir;
    }
    
    /**
     * Check if libraries are loaded.
     */
    public static boolean isLoaded() {
        return loaded;
    }
}
