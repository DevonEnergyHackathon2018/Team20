package com.dvn.safety;

import javax.enterprise.context.ApplicationScoped;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@ApplicationScoped
public class SafetyService {

    private static Map<Boundary, String> locations = new ConcurrentHashMap<>();

    private Map<String, SafetyOutput> outputs = new ConcurrentHashMap<>();

    private SafetyOutput lastOutput = null;
    private byte[] lastUpper = null;
    private byte[] lastLower = null;

    static {
        locations.put(new Boundary(-97.518760, 35.466508, -97.519484, 35.466941), "Devon Auditorium");
        locations.put(new Boundary(-97.518052, 35.466958, -97.519404, 35.467470), "Garden Wing");
        locations.put(new Boundary(-97.517087, 35.466566, -97.517947, 35.467165), "Devon Energy Center");
        locations.put(new Boundary(-97.619099, 35.486510, -97.664730, 35.540512), "Bethany, OK");
    }

    public SafetyOutput getOutput(String id) {
        SafetyOutput output = outputs.putIfAbsent(id, new SafetyOutput());
        if (output == null) {
            lastOutput = outputs.get(id);
            lastUpper = null;
            lastLower = null;
        }
        return outputs.get(id);
    }

    public String getLocation(double lat, double lon) {
        for (Map.Entry<Boundary, String> entry: locations.entrySet()) {
            Boundary boundary = entry.getKey();
            if (Math.abs(lon) > Math.abs(boundary.upperX) &&
                Math.abs(lon) < Math.abs(boundary.lowerX) &&
                Math.abs(lat) > Math.abs(boundary.upperY) &&
                Math.abs(lat) < Math.abs(boundary.lowerY) )
            {
                return entry.getValue();
            }
        }
        return lat + ", " + lon;
    }

    public SafetyOutput getLastOutput() {
        return lastOutput;
    }

    public byte[] getLastUpper() {
        return lastUpper;
    }

    public byte[] getLastLower() {
        return lastLower;
    }

    public void setLastOutput(SafetyOutput lastOutput) {
        this.lastOutput = lastOutput;
    }

    public void setLastUpper(byte[] lastUpper) {
        this.lastUpper = lastUpper;
    }

    public void setLastLower(byte[] lastLower) {
        this.lastLower = lastLower;
    }

    private static class Boundary {
        public double upperX;
        public double upperY;
        public double lowerX;
        public double lowerY;

        public Boundary(double upperX, double upperY, double lowerX, double lowerY) {
            this.upperX = upperX;
            this.upperY = upperY;
            this.lowerX = lowerX;
            this.lowerY = lowerY;
        }
    }
}
