package com.dvn.safety;

import javax.enterprise.context.ApplicationScoped;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@ApplicationScoped
public class SafetyService {

    private static Map<Boundary, String> locations = new ConcurrentHashMap<>();

    private static Map<String, SafetyOutput> outputs = new ConcurrentHashMap<>();

    static {
        locations.put(new Boundary(-180.0, -85, 180.0 ,85), "The Earth");
    }

    public SafetyOutput getOutput(String id) {
        outputs.putIfAbsent(id, new SafetyOutput());
        return outputs.get(id);
    }

    public String getLocation(double lat, double lon) {
        for (Map.Entry<Boundary, String> entry: locations.entrySet()) {
            Boundary boundary = entry.getKey();
            if (lon > boundary.upperX && lon < boundary.lowerX && lat > boundary.upperY && lat < boundary.lowerY)
                return entry.getValue();
        }
        return "Unknown Location";
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
