package com.dvn.safety;

import com.google.gson.Gson;
import com.squareup.okhttp.*;
import org.apache.commons.io.IOUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import javax.inject.Inject;
import javax.ws.rs.*;
import java.io.IOException;
import java.io.InputStream;

@Path("/")
public class SafetyEndpoint {

    @POST
    @Path("safe")
    @Produces("application/json")
    public SafetyOutput checkSafety(InputStream imageInput) throws IOException {
        byte[] byteArray = IOUtils.toByteArray(imageInput);

        OkHttpClient client = new OkHttpClient();
        RequestBody requestBody = RequestBody.create(MediaType.parse("application/octet-stream"), byteArray);
        Request request = new Request.Builder()
                .url("https://southcentralus.api.cognitive.microsoft.com/customvision/v2.0/Prediction/8fdcf5ed-6a1c-4909-9fde-f8db0aaf8e61/image?iterationId=ee975c2c-c704-49e4-b343-2d7eea4bd695")
                .post(requestBody)
                .header("Prediction-Key", "")
                .header("Content-Type", "application/octet-stream")
                .build();

        Response response = client.newCall(request).execute();
        String bodyString = response.body().string();
        //System.out.println("Response: " + bodyString);

        Gson gson = new Gson();
        MLOutput mlOutput = gson.fromJson(bodyString, MLOutput.class);

        return new SafetyOutput(mlOutput);
    }

    @GET
    @Path("test")
    public String test() {
        return "{\"success\":\"abc\"}";
    }
}
