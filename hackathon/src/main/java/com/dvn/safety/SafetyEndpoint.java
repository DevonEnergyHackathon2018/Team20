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
import java.util.concurrent.CountDownLatch;

@Path("/")
@Produces("application/json")
public class SafetyEndpoint {

    Logger log = LoggerFactory.getLogger(SafetyEndpoint.class);

    @Inject
    SafetyService safetyService;

    @POST
    @Path("safe")
    public SafetyOutput checkSafety(InputStream imageInput) throws IOException, InterruptedException {
        byte[] byteArray = IOUtils.toByteArray(imageInput);

        OkHttpClient client = new OkHttpClient();

        CountDownLatch asyncCalls = new CountDownLatch(1);

        RequestBody requestBody = RequestBody.create(MediaType.parse("application/octet-stream"), byteArray);
        Request request = new Request.Builder()
                .url("https://southcentralus.api.cognitive.microsoft.com/customvision/v2.0/Prediction/8fdcf5ed-6a1c-4909-9fde-f8db0aaf8e61/image?iterationId=b598241e-5dfd-4426-b69b-293082938521")
                .post(requestBody)
                .header("Prediction-Key", "24d42b1a16f34d6eb566969257e0196b")
                .header("Content-Type", "application/octet-stream")
                .build();

        //Response response = client.newCall(request).execute();
        //String bodyString = response.body().string();
        //System.out.println("Response: " + bodyString);

        Gson gson = new Gson();
        final MLOutput[] mlOutput1 = {null};

        Call call = client.newCall(request);
        call.enqueue(new Callback() {
            @Override
            public void onFailure(Request request, IOException e) {
                throw new IllegalStateException("call to AI services failed");
            }

            @Override
            public void onResponse(Response response) throws IOException {
                String bodyString = response.body().string();
                mlOutput1[0] = gson.fromJson(bodyString, MLOutput.class);
                asyncCalls.countDown();
            }

        });

        asyncCalls.await();

        return new SafetyOutput(mlOutput1[0]);
    }

    @POST
    @Path("geo")
    @Consumes("application/json")
    public GeoOutput getLocation(GeoInput geoInput) {
        return new GeoOutput(safetyService.getLocation(geoInput.lat, geoInput.lon));
    }

    @GET
    @Path("test")
    public String test() {
        return "{\"success\":\"abc\"}";
    }
}
