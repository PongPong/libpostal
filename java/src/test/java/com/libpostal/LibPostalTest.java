package com.libpostal;

import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

import java.util.Map;

/**
 * Unit tests for LibPostal JNI wrapper.
 * Tests are designed to be safe and avoid panics/crashes.
 */
@TestInstance(TestInstance.Lifecycle.PER_CLASS)
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
public class LibPostalTest {
    
    private static boolean libraryLoaded = false;
    private static boolean setupSuccessful = false;
    private static String skipReason = null;

    @BeforeAll
    public void setupLibrary() {
        try {
            // Try to load the library
            System.loadLibrary("postal");
            System.loadLibrary("postal_jni");
            libraryLoaded = true;
            
            // Try to initialize
            setupSuccessful = LibPostal.setup() && LibPostal.setupParser();
            
            if (!setupSuccessful) {
                skipReason = "LibPostal initialization failed - data files may be missing";
            }
        } catch (UnsatisfiedLinkError e) {
            skipReason = "Native libraries not found: " + e.getMessage();
            libraryLoaded = false;
        } catch (Exception e) {
            skipReason = "Unexpected error during setup: " + e.getMessage();
            libraryLoaded = false;
        }
    }

    @AfterAll
    public void teardownLibrary() {
        if (setupSuccessful) {
            try {
                LibPostal.teardownParser();
                LibPostal.teardown();
            } catch (Exception e) {
                // Ignore errors during cleanup
            }
        }
    }

    @Test
    @Order(1)
    @DisplayName("Library should load without errors")
    public void testLibraryLoading() {
        if (!libraryLoaded) {
            Assumptions.assumeTrue(false, skipReason);
        }
        assertTrue(libraryLoaded, "Native libraries should load successfully");
    }

    @Test
    @Order(2)
    @DisplayName("Setup should succeed with valid configuration")
    public void testSetup() {
        Assumptions.assumeTrue(libraryLoaded, skipReason);
        assertTrue(setupSuccessful, "LibPostal setup should succeed");
    }

    @Test
    @Order(3)
    @DisplayName("Parse simple US address")
    public void testParseSimpleAddress() {
        Assumptions.assumeTrue(setupSuccessful, skipReason);
        
        String address = "123 Main St, New York, NY 10001";
        AddressParserResponse response = LibPostal.parseAddress(address, "us");
        
        assertNotNull(response, "Response should not be null");
        assertNotNull(response.components, "Components should not be null");
        assertNotNull(response.labels, "Labels should not be null");
        assertEquals(response.components.length, response.labels.length, 
            "Components and labels should have same length");
        assertTrue(response.components.length > 0, "Should have at least one component");
    }

    @Test
    @Order(4)
    @DisplayName("Parse address without country code")
    public void testParseAddressNoCountry() {
        Assumptions.assumeTrue(setupSuccessful, skipReason);
        
        String address = "456 Oak Avenue, Los Angeles";
        AddressParserResponse response = LibPostal.parseAddress(address);
        
        assertNotNull(response, "Response should not be null");
        assertNotNull(response.components, "Components should not be null");
        assertNotNull(response.labels, "Labels should not be null");
        assertTrue(response.components.length > 0, "Should parse without country code");
    }

    @Test
    @Order(5)
    @DisplayName("Handle null address gracefully")
    public void testParseNullAddress() {
        Assumptions.assumeTrue(setupSuccessful, skipReason);
        
        // Should not crash - may return null or empty response
        assertDoesNotThrow(() -> {
            AddressParserResponse response = LibPostal.parseAddress(null, "us");
            // If it doesn't throw, check the response
            if (response != null) {
                assertNotNull(response.components, "Components should not be null if response exists");
                assertNotNull(response.labels, "Labels should not be null if response exists");
            }
        }, "Should handle null address without crashing");
    }

    @Test
    @Order(6)
    @DisplayName("Handle empty address gracefully")
    public void testParseEmptyAddress() {
        Assumptions.assumeTrue(setupSuccessful, skipReason);
        
        assertDoesNotThrow(() -> {
            AddressParserResponse response = LibPostal.parseAddress("", "us");
            // Empty address might return null or empty response
            if (response != null && response.components != null) {
                assertTrue(response.components.length >= 0, "Should handle empty address");
            }
        }, "Should handle empty address without crashing");
    }

    @Test
    @Order(7)
    @DisplayName("Handle very long address")
    public void testParseLongAddress() {
        Assumptions.assumeTrue(setupSuccessful, skipReason);
        
        StringBuilder longAddress = new StringBuilder();
        for (int i = 0; i < 100; i++) {
            longAddress.append("123 Main Street, ");
        }
        
        assertDoesNotThrow(() -> {
            AddressParserResponse response = LibPostal.parseAddress(longAddress.toString(), "us");
            assertNotNull(response, "Should handle long address");
        }, "Should handle very long address without crashing");
    }

    @Test
    @Order(8)
    @DisplayName("Handle special characters in address")
    public void testParseSpecialCharacters() {
        Assumptions.assumeTrue(setupSuccessful, skipReason);
        
        String address = "123 Münch€n Straß€, Bërlin!@#$%^&*()";
        
        assertDoesNotThrow(() -> {
            AddressParserResponse response = LibPostal.parseAddress(address, "de");
            assertNotNull(response, "Should handle special characters");
        }, "Should handle special characters without crashing");
    }

    @Test
    @Order(9)
    @DisplayName("Handle invalid country code")
    public void testParseInvalidCountryCode() {
        Assumptions.assumeTrue(setupSuccessful, skipReason);
        
        String address = "123 Main St";
        
        assertDoesNotThrow(() -> {
            AddressParserResponse response = LibPostal.parseAddress(address, "INVALID");
            // Should still parse, just ignore invalid country
            assertNotNull(response, "Should handle invalid country code");
        }, "Should handle invalid country code without crashing");
    }

    @Test
    @Order(10)
    @DisplayName("Parse international addresses")
    public void testParseInternationalAddresses() {
        Assumptions.assumeTrue(setupSuccessful, skipReason);
        
        String[][] addresses = {
            {"10 Downing Street, London SW1A 2AA, UK", "gb"},
            {"1600 Pennsylvania Avenue NW, Washington, DC 20500", "us"},
            {"Tour Eiffel, 5 Avenue Anatole France, 75007 Paris", "fr"},
            {"東京都渋谷区", "jp"}
        };
        
        for (String[] addressPair : addresses) {
            String address = addressPair[0];
            String country = addressPair[1];
            
            assertDoesNotThrow(() -> {
                AddressParserResponse response = LibPostal.parseAddress(address, country);
                assertNotNull(response, "Should parse " + country + " address");
                assertTrue(response.components.length > 0, 
                    "Should have components for " + country + " address");
            }, "Should parse international address: " + country);
        }
    }

    @Test
    @Order(11)
    @DisplayName("Test toMap conversion")
    public void testToMapConversion() {
        Assumptions.assumeTrue(setupSuccessful, skipReason);
        
        String address = "123 Main St, New York, NY 10001";
        AddressParserResponse response = LibPostal.parseAddress(address, "us");
        
        assertNotNull(response, "Response should not be null");
        
        Map<String, String> map = response.toMap();
        assertNotNull(map, "Map should not be null");
        assertTrue(map.size() > 0, "Map should contain entries");
        
        // Check that map has reasonable values
        for (Map.Entry<String, String> entry : map.entrySet()) {
            assertNotNull(entry.getKey(), "Map keys should not be null");
            assertNotNull(entry.getValue(), "Map values should not be null");
        }
    }

    @Test
    @Order(12)
    @DisplayName("Test address expansion")
    public void testExpandAddress() {
        Assumptions.assumeTrue(setupSuccessful, skipReason);
        
        String address = "123 Main St.";
        
        assertDoesNotThrow(() -> {
            String[] expansions = LibPostal.expandAddress(address);
            assertNotNull(expansions, "Expansions should not be null");
            assertTrue(expansions.length > 0, "Should have at least one expansion");
            
            // Check expansions are valid strings
            for (String expansion : expansions) {
                assertNotNull(expansion, "Each expansion should not be null");
                assertFalse(expansion.isEmpty(), "Expansions should not be empty");
            }
        }, "Address expansion should not crash");
    }

    @Test
    @Order(13)
    @DisplayName("Test expand with null address")
    public void testExpandNullAddress() {
        Assumptions.assumeTrue(setupSuccessful, skipReason);
        
        assertDoesNotThrow(() -> {
            String[] expansions = LibPostal.expandAddress(null);
            // Should handle gracefully - may return null or empty array
            if (expansions != null) {
                assertTrue(expansions.length >= 0, "Should handle null expand");
            }
        }, "Should handle null address expansion without crashing");
    }

    @Test
    @Order(14)
    @DisplayName("Test concurrent parsing (thread safety)")
    public void testConcurrentParsing() {
        Assumptions.assumeTrue(setupSuccessful, skipReason);
        
        String address = "123 Main St, New York, NY 10001";
        Thread[] threads = new Thread[5];
        
        for (int i = 0; i < threads.length; i++) {
            threads[i] = new Thread(() -> {
                for (int j = 0; j < 10; j++) {
                    assertDoesNotThrow(() -> {
                        AddressParserResponse response = LibPostal.parseAddress(address, "us");
                        assertNotNull(response, "Concurrent parse should work");
                    });
                }
            });
        }
        
        assertDoesNotThrow(() -> {
            for (Thread t : threads) {
                t.start();
            }
            for (Thread t : threads) {
                t.join(5000); // 5 second timeout
            }
        }, "Concurrent parsing should not crash");
    }

    @Test
    @Order(15)
    @DisplayName("Verify response toString doesn't crash")
    public void testResponseToString() {
        Assumptions.assumeTrue(setupSuccessful, skipReason);
        
        String address = "123 Main St, New York, NY 10001";
        AddressParserResponse response = LibPostal.parseAddress(address, "us");
        
        assertNotNull(response, "Response should not be null");
        
        assertDoesNotThrow(() -> {
            String str = response.toString();
            assertNotNull(str, "toString should return non-null");
            assertFalse(str.isEmpty(), "toString should return non-empty string");
        }, "toString should not crash");
    }

    @Test
    @Order(16)
    @DisplayName("Test multiple sequential parses")
    public void testMultipleSequentialParses() {
        Assumptions.assumeTrue(setupSuccessful, skipReason);
        
        String[] addresses = {
            "123 Main St, New York, NY 10001",
            "456 Oak Ave, Los Angeles, CA 90001",
            "789 Pine Rd, Chicago, IL 60601",
            "321 Elm Blvd, Houston, TX 77001",
            "654 Maple Dr, Phoenix, AZ 85001"
        };
        
        for (String address : addresses) {
            assertDoesNotThrow(() -> {
                AddressParserResponse response = LibPostal.parseAddress(address, "us");
                assertNotNull(response, "Sequential parse should work for: " + address);
                assertTrue(response.components.length > 0, "Should have components");
            }, "Sequential parsing should not fail");
        }
    }
}
