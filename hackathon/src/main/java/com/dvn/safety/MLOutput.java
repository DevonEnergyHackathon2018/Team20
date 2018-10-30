package com.dvn.safety;

import java.util.List;

public class MLOutput {

    public String id;
    public String project;
    public String iteration;
    public String created;
    public List<Prediction> predictions;

    public class Prediction {
        public double probability;
        public String tagId;
        public String tagName;
    }
}
