package com.libpostal;

public class Example {
    public static void main(String[] args) {
        // Initialize libpostal
        System.out.println("Initializing libpostal...");
        
        if (!LibPostal.setup()) {
            System.err.println("Failed to initialize libpostal");
            System.exit(1);
        }
        
        if (!LibPostal.setupParser()) {
            System.err.println("Failed to initialize address parser");
            LibPostal.teardown();
            System.exit(1);
        }
        
        System.out.println("Libpostal initialized successfully!\n");
        
        // Example 1: Parse a US address
        System.out.println("=== Example 1: US Address ===");
        String address1 = "781 Franklin Ave Crown Heights Brooklyn NYC NY 11216 USA";
        System.out.println("Input: " + address1);
        
        AddressParserResponse response1 = LibPostal.parseAddress(address1, "us");
        if (response1 != null) {
            System.out.println(response1);
        } else {
            System.out.println("Failed to parse address");
        }
        
        // Example 2: Parse a UK address
        System.out.println("\n=== Example 2: UK Address ===");
        String address2 = "10 Downing Street, Westminster, London SW1A 2AA, UK";
        System.out.println("Input: " + address2);
        
        AddressParserResponse response2 = LibPostal.parseAddress(address2, "gb");
        if (response2 != null) {
            System.out.println(response2);
        }
        
        // Example 3: Expand address (normalization)
        System.out.println("\n=== Example 3: Address Expansion ===");
        String address3 = "123 Main St. Apt. 5B";
        System.out.println("Input: " + address3);
        System.out.println("Expansions:");
        
        String[] expansions = LibPostal.expandAddress(address3);
        if (expansions != null) {
            for (String expansion : expansions) {
                System.out.println("  - " + expansion);
            }
        }
        
        // Example 4: Use map interface
        System.out.println("\n=== Example 4: Map Interface ===");
        String address4 = "1600 Pennsylvania Avenue NW, Washington, DC 20500";
        System.out.println("Input: " + address4);
        
        AddressParserResponse response4 = LibPostal.parseAddress(address4, "us");
        if (response4 != null) {
            var map = response4.toMap();
            System.out.println("House number: " + map.get("house_number"));
            System.out.println("Road: " + map.get("road"));
            System.out.println("City: " + map.get("city"));
            System.out.println("State: " + map.get("state"));
            System.out.println("Postcode: " + map.get("postcode"));
        }
        
        // Cleanup
        System.out.println("\nCleaning up...");
        LibPostal.teardownParser();
        LibPostal.teardown();
        System.out.println("Done!");
    }
}
