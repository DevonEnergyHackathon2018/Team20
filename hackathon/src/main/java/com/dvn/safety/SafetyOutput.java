package com.dvn.safety;

public class SafetyOutput {

    public boolean glasses;
    public boolean hardhat;
    public boolean coat;
    public double glasses_probability;
    public double hardhat_probability;
    public double coat_probability;

    public static float hardhat_threshold = 0.6f;
    public static float glasses_threshold = 0.7f;
    public static float coat_threshold = 0.5f;

    public SafetyOutput(MLOutput mlOutput) {
        for (MLOutput.Prediction prediction : mlOutput.predictions) {
            switch(prediction.tagName) {
                case "Hard hat":
                    hardhat = prediction.probability > hardhat_threshold;
                    hardhat_probability = prediction.probability;
                    break;
                case "frc":
                    coat = prediction.probability > coat_threshold;
                    coat_probability = prediction.probability;
                    break;
                case "safety glass":
                    glasses = prediction.probability > glasses_threshold;
                    glasses_probability = prediction.probability;
            }
        }
    }

}
