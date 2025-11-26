package com.libpostal;

public class LibPostal {
    
    static {
        // Load native libraries
        System.loadLibrary("postal");
        System.loadLibrary("postal_jni");
    }

    // Setup and teardown methods
    public static native boolean setup();
    public static native boolean setupDatadir(String datadir);
    public static native void teardown();
    
    public static native boolean setupParser();
    public static native boolean setupParserDatadir(String datadir);
    public static native void teardownParser();

    // Address parsing
    public static native AddressParserResponse parseAddress(String address, String language, String country);
    
    public static AddressParserResponse parseAddress(String address) {
        return parseAddress(address, null, null);
    }
    
    public static AddressParserResponse parseAddress(String address, String country) {
        return parseAddress(address, null, country);
    }

    // Address expansion
    public static native String[] expandAddress(String address, Object options);
    
    public static String[] expandAddress(String address) {
        return expandAddress(address, null);
    }
}
