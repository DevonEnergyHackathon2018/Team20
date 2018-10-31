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
import java.util.Collections;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

@Path("/")
@Produces("application/json")
public class SafetyEndpoint {

    Logger log = LoggerFactory.getLogger(SafetyEndpoint.class);

    private static String PERSON_API = "https://southcentralus.api.cognitive.microsoft.com/customvision/v2.0/Prediction/a72a5e90-3c3d-4c50-b630-adcf40ec8268/image";
    private static String HARDHAT_API ="https://southcentralus.api.cognitive.microsoft.com/customvision/v2.0/Prediction/821891b4-3426-4022-aab9-4321f9ded114/image";
    private static String GLASSES_API ="https://southcentralus.api.cognitive.microsoft.com/customvision/v2.0/Prediction/101aad8d-d44d-4960-8f07-5d31e64461e8/image";
    private static String FRC_API ="https://southcentralus.api.cognitive.microsoft.com/customvision/v2.0/Prediction/ebe32ee7-395d-41a5-81dd-d80a682beb7f/image";
    private static String BOOTS_API = "https://southcentralus.api.cognitive.microsoft.com/customvision/v2.0/Prediction/7ae2298a-a848-471d-be41-57ef3db7973e/image";

    @Inject
    SafetyService safetyService;

    @POST
    @Path("image/{id}/upper")
    public Map<String, Boolean> uploadUpper(@PathParam("id") String id, InputStream imageInput) throws IOException, InterruptedException {
        log.info("Uploading upper for id: {}", id);

        SafetyOutput output = safetyService.getOutput(id);
        CountDownLatch asyncCalls = new CountDownLatch(4);

        byte[] byteArray = IOUtils.toByteArray(imageInput);
        imageCallAsync(byteArray, PERSON_API, output, asyncCalls, true);
        imageCallAsync(byteArray, HARDHAT_API, output, asyncCalls, false);
        imageCallAsync(byteArray, GLASSES_API, output, asyncCalls, false);
        imageCallAsync(byteArray, FRC_API, output, asyncCalls, false);

        asyncCalls.await();
        safetyService.setLastUpper(byteArray);
        return Collections.singletonMap("success", Boolean.TRUE);
    }

    @POST
    @Path("image/{id}/lower")
    public Map<String, Boolean> uploadLower(@PathParam("id") String id, InputStream imageInput) throws IOException, InterruptedException {
        log.info("Uploading lower for id: {}", id);

        SafetyOutput output = safetyService.getOutput(id);
        CountDownLatch asyncCalls = new CountDownLatch(1);

        byte[] byteArray = IOUtils.toByteArray(imageInput);
        imageCallAsync(byteArray, BOOTS_API, output, asyncCalls, false);

        asyncCalls.await();
        safetyService.setLastLower(byteArray);
        return Collections.singletonMap("success", Boolean.TRUE);
    }

    @POST
    @Path("geo/{id}")
    public Map<String, Boolean> uploadGeo(@PathParam("id") String id, GeoInput geoInput) {
        log.info("Uploading geo for id: {}", id);

        SafetyOutput output = safetyService.getOutput(id);
        output.location = safetyService.getLocation(geoInput.lat, geoInput.lon);
        log.info("Location for {}, {} - {}", geoInput.lat, geoInput.lon, output.location);

        return Collections.singletonMap("success", Boolean.TRUE);
    }

    @GET
    @Path("result/{id}")
    public SafetyOutput getResult(@PathParam("id") String id) {
        log.info("Returning result for id: {} - {}", id, safetyService.getOutput(id));
        return safetyService.getOutput(id);
    }

    @GET
    @Path("last")
    public SafetyOutput getLastOutput() {
        return safetyService.getLastOutput();
    }

    @GET
    @Path("lastupper")
    @Produces("image/jpeg")
    public javax.ws.rs.core.Response getLastUpperImage() {
        javax.ws.rs.core.CacheControl cc = new javax.ws.rs.core.CacheControl();
        cc.setNoCache(true);
        cc.setNoStore(true);
        cc.setMustRevalidate(true);
        cc.setMaxAge(0);
        return javax.ws.rs.core.Response.ok(safetyService.getLastUpper()).cacheControl(cc).build();
    }

    @GET
    @Path("lastlower")
    @Produces("image/jpeg")
    public javax.ws.rs.core.Response getLastLowerImage() {
        javax.ws.rs.core.CacheControl cc = new javax.ws.rs.core.CacheControl();
        cc.setNoCache(true);
        cc.setNoStore(true);
        cc.setMustRevalidate(true);
        cc.setMaxAge(0);
        return javax.ws.rs.core.Response.ok(safetyService.getLastLower()).cacheControl(cc).build();
    }

    @POST
    @Path("geo")
    @Consumes("application/json")
    public GeoOutput getLocation(GeoInput geoInput) {
        return new GeoOutput(safetyService.getLocation(geoInput.lat, geoInput.lon));
    }

    private Call createImageCall(byte[] byteArray, String url) throws IOException {
        RequestBody requestBody = RequestBody.create(MediaType.parse("application/octet-stream"), byteArray);
        Request request = new Request.Builder()
                .url(url)
                .post(requestBody)
                .header("Prediction-Key", "")
                .header("Content-Type", "application/octet-stream")
                .build();

        OkHttpClient client = new OkHttpClient();
        client.setReadTimeout(30, TimeUnit.SECONDS);

        return client.newCall(request);
    }

    private void imageCallAsync(byte[] byteArray, String url, SafetyOutput output, CountDownLatch countDownLatch, boolean checkPerson) throws IOException {
        createImageCall(byteArray, url).enqueue(new Callback() {
            @Override
            public void onFailure(Request request, IOException e) {
                countDownLatch.countDown();
                throw new IllegalStateException("Call to Cognitive Services failed");
            }

            @Override
            public void onResponse(Response response) throws IOException {
                String bodyString = response.body().string();
                log.info("Got a response from {} - {} - {} ", url, byteArray.length, bodyString);
                MLOutput mlOutput = new Gson().fromJson(bodyString, MLOutput.class);
                output.update(mlOutput, checkPerson);
                countDownLatch.countDown();
            }
        });
    }

}
