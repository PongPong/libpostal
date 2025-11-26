package com.libpostal;

import java.util.HashMap;
import java.util.Map;

public class AddressParserResponse {
    public String[] components;
    public String[] labels;

    public AddressParserResponse() {
    }

    public AddressParserResponse(String[] components, String[] labels) {
        this.components = components;
        this.labels = labels;
    }

    public Map<String, String> toMap() {
        Map<String, String> result = new HashMap<>();
        if (components != null && labels != null) {
            for (int i = 0; i < Math.min(components.length, labels.length); i++) {
                result.put(labels[i], components[i]);
            }
        }
        return result;
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("AddressParserResponse{\n");
        if (components != null && labels != null) {
            for (int i = 0; i < Math.min(components.length, labels.length); i++) {
                sb.append("  ").append(labels[i]).append(": ").append(components[i]).append("\n");
            }
        }
        sb.append("}");
        return sb.toString();
    }
}
