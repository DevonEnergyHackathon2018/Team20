package com.dvn.safety;

public class SafetyOutput {

    public boolean glasses;
    public boolean hardhat;
    public boolean coat;

    public static float threshold = 50.0f;

    public SafetyOutput(MLOutput mlOutput) {
        for (MLOutput.Prediction prediction : mlOutput.predictions) {
            switch(prediction.tagName) {
                case "Hard hat":
                    hardhat = prediction.probability > threshold;
                case "frc":
                    coat = prediction.probability > threshold;
                case "safety glass":
                    glasses = prediction.probability > threshold;
            }
        }
    }

}
