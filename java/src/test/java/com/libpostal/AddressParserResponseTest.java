package com.libpostal;

import org.junit.jupiter.api.*;
import static org.junit.jupiter.api.Assertions.*;

import java.util.Map;

/**
 * Unit tests for AddressParserResponse class.
 * These tests don't require native library loading.
 */
public class AddressParserResponseTest {

    @Test
    @DisplayName("Create response with null arrays")
    public void testCreateWithNullArrays() {
        assertDoesNotThrow(() -> {
            AddressParserResponse response = new AddressParserResponse(null, null);
            assertNotNull(response, "Response should be created");
            assertNull(response.components, "Components should be null");
            assertNull(response.labels, "Labels should be null");
        }, "Should handle null arrays without crashing");
    }

    @Test
    @DisplayName("Create response with empty arrays")
    public void testCreateWithEmptyArrays() {
        assertDoesNotThrow(() -> {
            String[] empty = new String[0];
            AddressParserResponse response = new AddressParserResponse(empty, empty);
            assertNotNull(response, "Response should be created");
            assertEquals(0, response.components.length, "Components should be empty");
            assertEquals(0, response.labels.length, "Labels should be empty");
        }, "Should handle empty arrays without crashing");
    }

    @Test
    @DisplayName("Create response with valid data")
    public void testCreateWithValidData() {
        String[] components = {"123", "Main St", "New York"};
        String[] labels = {"house_number", "road", "city"};
        
        AddressParserResponse response = new AddressParserResponse(components, labels);
        
        assertNotNull(response, "Response should be created");
        assertArrayEquals(components, response.components, "Components should match");
        assertArrayEquals(labels, response.labels, "Labels should match");
    }

    @Test
    @DisplayName("toMap with null arrays returns empty map")
    public void testToMapWithNullArrays() {
        AddressParserResponse response = new AddressParserResponse(null, null);
        
        assertDoesNotThrow(() -> {
            Map<String, String> map = response.toMap();
            assertNotNull(map, "Map should not be null");
            assertEquals(0, map.size(), "Map should be empty");
        }, "toMap should not crash with null arrays");
    }

    @Test
    @DisplayName("toMap with empty arrays returns empty map")
    public void testToMapWithEmptyArrays() {
        String[] empty = new String[0];
        AddressParserResponse response = new AddressParserResponse(empty, empty);
        
        Map<String, String> map = response.toMap();
        
        assertNotNull(map, "Map should not be null");
        assertEquals(0, map.size(), "Map should be empty");
    }

    @Test
    @DisplayName("toMap with valid data creates correct map")
    public void testToMapWithValidData() {
        String[] components = {"123", "Main St", "New York", "NY", "10001"};
        String[] labels = {"house_number", "road", "city", "state", "postcode"};
        
        AddressParserResponse response = new AddressParserResponse(components, labels);
        Map<String, String> map = response.toMap();
        
        assertNotNull(map, "Map should not be null");
        assertEquals(5, map.size(), "Map should have 5 entries");
        assertEquals("123", map.get("house_number"));
        assertEquals("Main St", map.get("road"));
        assertEquals("New York", map.get("city"));
        assertEquals("NY", map.get("state"));
        assertEquals("10001", map.get("postcode"));
    }

    @Test
    @DisplayName("toMap with mismatched array lengths")
    public void testToMapWithMismatchedLengths() {
        String[] components = {"123", "Main St", "New York"};
        String[] labels = {"house_number", "road"}; // One less
        
        AddressParserResponse response = new AddressParserResponse(components, labels);
        
        assertDoesNotThrow(() -> {
            Map<String, String> map = response.toMap();
            assertNotNull(map, "Map should not be null");
            assertEquals(2, map.size(), "Map should use minimum length");
            assertEquals("123", map.get("house_number"));
            assertEquals("Main St", map.get("road"));
            assertNull(map.get("New York"), "Extra component should not be mapped");
        }, "Should handle mismatched lengths gracefully");
    }

    @Test
    @DisplayName("toMap with null elements")
    public void testToMapWithNullElements() {
        String[] components = {"123", null, "New York"};
        String[] labels = {"house_number", "road", "city"};
        
        AddressParserResponse response = new AddressParserResponse(components, labels);
        
        assertDoesNotThrow(() -> {
            Map<String, String> map = response.toMap();
            assertNotNull(map, "Map should not be null");
            assertEquals(3, map.size(), "Map should have all entries");
            assertEquals("123", map.get("house_number"));
            assertNull(map.get("road"), "Null component should map to null");
            assertEquals("New York", map.get("city"));
        }, "Should handle null elements without crashing");
    }

    @Test
    @DisplayName("toMap with duplicate labels")
    public void testToMapWithDuplicateLabels() {
        String[] components = {"123", "Main St", "456"};
        String[] labels = {"house_number", "road", "house_number"}; // Duplicate
        
        AddressParserResponse response = new AddressParserResponse(components, labels);
        Map<String, String> map = response.toMap();
        
        assertNotNull(map, "Map should not be null");
        // Map should overwrite with last value
        assertEquals("456", map.get("house_number"), "Should use last value for duplicate key");
        assertEquals("Main St", map.get("road"));
    }

    @Test
    @DisplayName("toString with null arrays")
    public void testToStringWithNullArrays() {
        AddressParserResponse response = new AddressParserResponse(null, null);
        
        assertDoesNotThrow(() -> {
            String str = response.toString();
            assertNotNull(str, "toString should not return null");
            assertTrue(str.contains("AddressParserResponse"), "Should contain class name");
        }, "toString should not crash with null arrays");
    }

    @Test
    @DisplayName("toString with empty arrays")
    public void testToStringWithEmptyArrays() {
        String[] empty = new String[0];
        AddressParserResponse response = new AddressParserResponse(empty, empty);
        
        String str = response.toString();
        
        assertNotNull(str, "toString should not return null");
        assertTrue(str.contains("AddressParserResponse"), "Should contain class name");
    }

    @Test
    @DisplayName("toString with valid data")
    public void testToStringWithValidData() {
        String[] components = {"123", "Main St", "New York"};
        String[] labels = {"house_number", "road", "city"};
        
        AddressParserResponse response = new AddressParserResponse(components, labels);
        String str = response.toString();
        
        assertNotNull(str, "toString should not return null");
        assertTrue(str.contains("house_number"), "Should contain label");
        assertTrue(str.contains("123"), "Should contain component");
        assertTrue(str.contains("road"), "Should contain label");
        assertTrue(str.contains("Main St"), "Should contain component");
    }

    @Test
    @DisplayName("toString with null elements")
    public void testToStringWithNullElements() {
        String[] components = {"123", null, "New York"};
        String[] labels = {"house_number", null, "city"};
        
        AddressParserResponse response = new AddressParserResponse(components, labels);
        
        assertDoesNotThrow(() -> {
            String str = response.toString();
            assertNotNull(str, "toString should not return null");
        }, "toString should handle null elements without crashing");
    }

    @Test
    @DisplayName("Default constructor creates empty response")
    public void testDefaultConstructor() {
        AddressParserResponse response = new AddressParserResponse();
        
        assertNotNull(response, "Response should be created");
        assertNull(response.components, "Components should be null by default");
        assertNull(response.labels, "Labels should be null by default");
    }

    @Test
    @DisplayName("Response is mutable")
    public void testResponseIsMutable() {
        AddressParserResponse response = new AddressParserResponse();
        
        String[] components = {"123", "Main St"};
        String[] labels = {"house_number", "road"};
        
        response.components = components;
        response.labels = labels;
        
        assertArrayEquals(components, response.components, "Components should be set");
        assertArrayEquals(labels, response.labels, "Labels should be set");
    }

    @Test
    @DisplayName("toMap creates new map each time")
    public void testToMapCreatesNewMap() {
        String[] components = {"123", "Main St"};
        String[] labels = {"house_number", "road"};
        AddressParserResponse response = new AddressParserResponse(components, labels);
        
        Map<String, String> map1 = response.toMap();
        Map<String, String> map2 = response.toMap();
        
        assertNotSame(map1, map2, "Each call should create a new map");
        assertEquals(map1, map2, "Maps should have same content");
    }

    @Test
    @DisplayName("Modifying arrays after construction affects response")
    public void testArraysAreNotCopied() {
        String[] components = {"123", "Main St"};
        String[] labels = {"house_number", "road"};
        
        AddressParserResponse response = new AddressParserResponse(components, labels);
        
        // Modify original arrays
        components[0] = "456";
        labels[0] = "different";
        
        // Response should reflect changes (arrays not copied)
        assertEquals("456", response.components[0], "Components should reference same array");
        assertEquals("different", response.labels[0], "Labels should reference same array");
    }
}
