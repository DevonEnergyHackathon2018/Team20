package com.dvn.safety;

public class SafetyOutput {

    private static float HARDHAT_THRESHOLD = 0.5f;
    private static float GLASSES_THRESHOLD = 0.5f;
    private static float FRC_THRESHOLD = 0.5f;
    private static float BOOTS_THRESHOLD = 0.5f;
    private static float PERSON_THRESHOLD = 0.5f;

    public String person = "Unknown";
    public String location;
    public boolean glasses;
    public boolean hardhat;
    public boolean frc;
    public boolean boots;
    public double glasses_probability;
    public double hardhat_probability;
    public double frc_probability;
    public double boots_probability;

    public SafetyOutput() { }

    public void update(MLOutput mlOutput, boolean checkPerson) {
        double highestPerson = 0;
        for (MLOutput.Prediction prediction : mlOutput.predictions) {
            if (checkPerson) {
                if (prediction.probability > highestPerson && prediction.probability > PERSON_THRESHOLD) {
                    person = prediction.tagName;
                    highestPerson = prediction.probability;
                }
            }
            else {
                switch (prediction.tagName) {
                    case "hard hat":
                        hardhat = prediction.probability > HARDHAT_THRESHOLD;
                        hardhat_probability = prediction.probability;
                        break;
                    case "frc":
                        frc = prediction.probability > FRC_THRESHOLD;
                        frc_probability = prediction.probability;
                        break;
                    case "safety glasses":
                        glasses = prediction.probability > GLASSES_THRESHOLD;
                        glasses_probability = prediction.probability;
                    case "boots":
                        boots = prediction.probability > BOOTS_THRESHOLD;
                        boots_probability = prediction.probability;
                }
            }
        }
    }

    @Override
    public String toString() {
        return "SafetyOutput{" +
                "person='" + person + '\'' +
                ", location='" + location + '\'' +
                ", glasses=" + glasses +
                ", hardhat=" + hardhat +
                ", frc=" + frc +
                ", boots=" + boots +
                ", glasses_probability=" + glasses_probability +
                ", hardhat_probability=" + hardhat_probability +
                ", frc_probability=" + frc_probability +
                ", boots_probability=" + boots_probability +
                '}';
    }
}
